#
# Copyright 2013-2015, Noah Kantrowitz
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

require 'chef/dsl/recipe'

require 'poise/helpers/subcontext_block'
require 'poise/helpers/subresources/default_containers'


module Poise
  module Helpers
    module Subresources
      # A resource mixin for subresource containers.
      #
      # @since 1.0.0
      module Container
        # A resource collection that has much more condensed text output. This
        # is used to show the value of @subresources during Chef's error formatting.
        # @api private
        class NoPrintingResourceCollection < Chef::ResourceCollection
          def to_text
            "[#{all_resources.map(&:to_s).join(', ')}]"
          end
        end

        include SubcontextBlock
        include Chef::DSL::Recipe

        attr_reader :subresources

        def initialize(*args)
          super
          @subresources = NoPrintingResourceCollection.new
        end

        def after_created
          super
          # Register
          Poise::Helpers::Subresources::DefaultContainers.register!(self, run_context)
          unless @subresources.empty?
            Chef::Log.debug("[#{self}] Adding subresources to collection:")
            # Because after_create is run before adding the container to the resource collection
            # we need to jump through some hoops to get it swapped into place.
            self_ = self
            order_fixer = Chef::Resource::RubyBlock.new('subresource_order_fixer', @run_context)
            order_fixer.block do
              collection = self_.run_context.resource_collection
              # Delete the current container resource from its current position.
              collection.all_resources.delete(self_)
              # Replace the order fixer with the container so it runs before all
              # subresources.
              collection.all_resources[collection.iterator.position] = self_
              # Hack for Chef 11 to reset the resources_by_name position too.
              # @todo Remove this when I drop support for Chef 11.
              if resources_by_name = collection.instance_variable_get(:@resources_by_name)
                resources_by_name[self_.to_s] = collection.iterator.position
              end
              # Step back so we re-run the "current" resource, which is now the
              # container.
              collection.iterator.skip_back
            end
            @run_context.resource_collection.insert(order_fixer)
            @subresources.each do |r|
              Chef::Log.debug("   * #{r}")
              @run_context.resource_collection.insert(r)
            end
          end
        end

        def declare_resource(type, name, created_at=nil, &block)
          Chef::Log.debug("[#{self}] Creating subresource from #{type}(#{name})")
          self_ = self
          # Used to break block context, non-local return from subcontext_block.
          resource = []
          # Grab the caller so we can make the subresource look like it comes from
          # correct place.
          created_at ||= caller[0]
          # Run this inside a subcontext to avoid adding to the current resource collection.
          # It will end up added later, indirected via @subresources to ensure ordering.
          subcontext_block do
            namespace = if self.class.container_namespace == true
              # If the value is true, use the name of the container resource.
              self.name
            elsif self.class.container_namespace.is_a?(Proc)
              instance_eval(&self.class.container_namespace)
            else
              self.class.container_namespace
            end
            sub_name = if name && !name.empty?
              if namespace
                "#{namespace}::#{name}"
              else
                name
              end
            else
              # If you pass in nil or '', you just get the namespace or parent name.
              namespace || self.name
            end
            resource << super(type, sub_name, created_at) do
              # Apply the correct parent before anything else so it is available
              # in after_created for the subresource.
              parent(self_) if respond_to?(:parent)
              # Run the resource block.
              instance_exec(&block) if block
            end
          end
          # Try and add to subresources. For normal subresources this is handled
          # in the after_created.
          register_subresource(resource.first) if resource.first
          # Return whatever we have
          resource.first
        end

        def register_subresource(resource)
          subresources.lookup(resource)
        rescue Chef::Exceptions::ResourceNotFound
          Chef::Log.debug("[#{self}] Adding #{resource} to subresources")
          subresources.insert(resource)
        end

        private

        # Thanks Array.flatten, big help you are. Specifically the
        # method_missing in the recipe DSL will make a flatten on an array of
        # resources fail, so make this safe.
        def to_ary
          nil
        end

        # @!classmethods
        module ClassMethods
          def container_namespace(val=nil)
            @container_namespace = val unless val.nil?
            if @container_namespace.nil?
              # Not set here, look at the superclass of true by default for backwards compat.
              superclass.respond_to?(:container_namespace) ? superclass.container_namespace : true
            else
              @container_namespace
            end
          end

          def included(klass)
            super
            klass.extend(ClassMethods)
          end
        end

        extend ClassMethods
      end
    end
  end
end
