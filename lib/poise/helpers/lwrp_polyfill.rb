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

require 'poise/utils/resource_provider_mixin'


module Poise
  module Helpers
    # A resource and provider mixin to add back some compatability with Chef's
    # LWRPBase classes.
    #
    # @since 1.0.0
    module LWRPPolyfill
      include Poise::Utils::ResourceProviderMixin

      # Provide default_action and actions like LWRPBase but better equipped for subclassing.
      module Resource
        def initialize(*args)
          super
          # Try to not stomp on stuff if already set in a parent
          @action = self.class.default_action if @action == :nothing
          (@allowed_actions << self.class.actions).flatten!.uniq!
        end

        # @!classmethods
        module ClassMethods
          def default_action(name=nil)
            if name
              @default_action = name
              actions(name)
            end
            @default_action || ( respond_to?(:superclass) && superclass.respond_to?(:default_action) && superclass.default_action ) || actions.first || :nothing
          end

          def actions(*names)
            @actions ||= ( respond_to?(:superclass) && superclass.respond_to?(:actions) ? superclass.actions.dup : [] )
            (@actions << names).flatten!.uniq!
            @actions
          end

          def attribute(name, opts)
            # Ruby 1.8 can go to hell
            define_method(name) do |arg=nil, &block|
              arg = block if arg.nil? # Try to allow passing either
              set_or_return(name, arg, opts)
            end
          end

          def included(klass)
            super
            klass.extend(ClassMethods)
          end
        end

        extend ClassMethods
      end

      # Helper to handle load_current_resource for direct subclasses of Provider
      module Provider
        # @!classmethods
        module ClassMethods
          def included(klass)
            super
            klass.extend(ClassMethods)

            # Mask Chef::Provider#load_current_resource because it throws NotImplementedError.
            if klass.is_a?(Class) && klass.superclass == Chef::Provider
              klass.class_exec do
                def load_current_resource
                end
              end
            end

            # Reinstate the Chef DSL, removed in Chef 12.
            klass.class_exec { include Chef::DSL::Recipe }
          end
        end

        extend ClassMethods
      end
    end
  end
end
