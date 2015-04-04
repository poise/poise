#
# Copyright 2015, Noah Kantrowitz
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
# http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

require 'chef/node'
require 'chef/node_map'

require 'poise/defined_in'
require 'poise/error'


module Poise
  # TODO
  #
  # @since 1.1.0
  # @example
  #   TODO
  module Inversion
    module Resource
      # @overload options(val=nil)
      #   Set or return provider options for all providers.
      #   @param val [Hash] Provider options to set.
      #   @return [Hash]
      #   @example
      #     my_resource 'thing_one' do
      #       options depends: 'thing_two'
      #     end
      # @overload options(provider, val=nil)
      #   Set or return provider options for a specific provider.
      #   @param provider [Symbol] Provider to set for.
      #   @param val [Hash] Provider options to set.
      #   @return [Hash]
      #   @example
      #     my_resource 'thing_one' do
      #       options :my_provider, depends: 'thing_two'
      #     end
      def options(provider=nil, val=nil)
        key = :options
        if !val && provider.is_a?(Hash)
          val = provider
        elsif provider
          key = :"options_#{provider}"
        end
        set_or_return(key, val ? Mash.new(val) : val, kind_of: Hash, default: lazy { Mash.new })
      end

      # Allow setting the provider directly using the same names as the attribute
      # settings.
      #
      # @param val [String, Symbol, Class, nil] Value to set the provider to.
      # @return [Class]
      # @example
      #   my_resource 'thing_one' do
      #     provider :my_provider
      #   end
      def provider(val=nil)
        if val && !val.is_a?(Class)
          provider_class = Poise::Inversion.provider_for(resource_name, node, val)
          Chef::Log.debug("#{self} Checking for an inversion provider for #{val}: #{provider_class && provider_class.name}")
          val = provider_class if provider_class
        end
        super
      end
    end

    module Provider
      include Poise::DefinedIn

      # (see .inversion_options)
      def options
        @options ||= self.class.inversion_options(node, new_resource)
      end

      # @!classmethods
      module ClassMethods
        def inversion_resource(val=nil)
          if val
            val = val.resource_name if val.is_a?(Class)
            Chef::Log.debug("[#{self.name}] Setting inversion resource to #{val}")
            @poise_inversion_resource = val.to_sym
          end
          @poise_inversion_resource
        end

        def inversion_attribute(val=nil)
          if val
            # Coerce to an array of strings.
            val = Array(val).map {|name| name.to_s }
            @poise_inversion_attribute = val
          end
          @poise_inversion_attribute
        end

        def resolve_inversion_attribute(node)
          # Default to using just the name of the cookbook.
          attribute_names = inversion_attribute || [poise_defined_in_cookbook(node.run_context)]
          attribute_names.inject(node) do |memo, key|
            memo[key] || begin
              raise Poise::Error.new("Attribute #{key} not set when expanding inversion attribute for #{self.name}: #{memo}")
            end
          end
        end

        # Compile all the different levels of inversion options together.
        #
        # @param node [Chef::Node] Node to load from.
        # @param resource [Chef::Resource] Resource to load from.
        # @return [Hash]
        def inversion_options(node, resource)
          Mash.new.tap do |opts|
            attrs = resolve_inversion_attribute(node)
            # Cast the run state to a Mash because string vs. symbol keys. I can
            # at least promise :poise_inversion will be a sym so cut down on the
            # amount of data to convert.
            run_state = Mash.new(node.run_state.fetch(:poise_inversion, {}))[resource.name] || {}
            opts.update(resource.options)
            opts.update(provider: attrs['provider']) if attrs['provider']
            opts.update(attrs['options']) if attrs['options']
            opts.update(resource.options(provides))
            opts.update(attrs[resource.name]) if attrs[resource.name]
            opts.update(run_state['*']) if run_state['*']
            opts.update(run_state[provides]) if run_state[provides]
          end
        end

        def resolve_inversion_provider(node, resource)
          inversion_options(node, resource)['provider'] || 'auto'
        end

        # Override the normal #provides to set the inversion provider name
        # instead of adding to the normal provider map.
        #
        # @overload provides()
        #   Return the inversion provider name for the class.
        #   @return [Symbol]
        # @overload provides(name, opts={}, &block)
        #   Set the inversion provider name for the class.
        #   @param name [Symbol] Provider name.
        #   @param opts [Hash] NodeMap filter options.
        #   @param block [Proc] NodeMap filter proc.
        #   @return [Symbol]
        def provides(name=nil, opts={}, &block)
          if name
            raise Poise::Error.new("Inversion resource name not set for #{self.name}") unless inversion_resource
            @poise_inversion_provider = name
            Chef::Log.debug("[#{self.name}] Setting inversion provider name to #{name}")
            Poise::Inversion.provider_map(inversion_resource).set(name.to_sym, self, opts, &block)
          end
          @poise_inversion_provider
        end

        # Override the default #provides? to check for our inverted providers.
        #
        # @api private
        # @param node [Chef::Node] Node to use for attribute checks.
        # @param resource [Chef::Resource] Resource instance to match.
        # @return [Boolean]
        def provides?(node, resource)
          raise Poise::Error.new("Inversion resource name not set for #{self.name}") unless inversion_resource
          return false unless resource.resource_name == inversion_resource
          provider_name = resolve_inversion_provider(node, resource)
          Chef::Log.debug("[#{resource}] Checking provides? on #{self.name}. Got provider_name #{provider_name.inspect}")
          provider_name == provides.to_s || ( provider_name == 'auto' && provides_auto?(node, resource) )
        end

        # Subclass hook to provide auto-detection for providers.
        #
        # @param node [Chef::Node] Node to check against.
        # @param resource [Chef::Resource] Resource to check against.
        # @return [Boolean]
        def provides_auto?(node, resource)
          false
        end

        def included(klass)
          super
          klass.extend(ClassMethods)
        end
      end

      extend ClassMethods
    end

    # Include in the correct module for the class type.
    #
    # @api private
    def self.included(klass)
      super
      if klass < Chef::Resource
        klass.class_exec { include Poise::Inversion::Resource }
      elsif klass < Chef::Provider
        klass.class_exec { include Poise::Inversion::Provider }
      end
    end

    # The provider map for a given resource type.
    #
    # @param resource_type [Symbol] Resource type in DSL format.
    # @return [Chef::NodeMap]
    # @example
    #   Poise::Inversion.provider_map(:my_resource)
    def self.provider_map(resource_type)
      @provider_maps ||= {}
      @provider_maps[resource_type.to_sym] ||= Chef::NodeMap.new
    end

    # Find a specific provider class for a resource.
    #
    # @param resource_type [Symbol] Resource type in DSL format.
    # @param node [Chef::Node] Node to use for the lookup.
    # @param provider_type [Symbol] Provider type in DSL format.
    # @return [Class]
    # @example
    #   Poise::Inversion.provider_for(:my_resource, node, :my_provider)
    def self.provider_for(resource_type, node, provider_type)
      provider_map(resource_type).get(node, provider_type.to_sym)
    end
  end
end
