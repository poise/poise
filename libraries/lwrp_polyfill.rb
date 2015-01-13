#
# Author:: Noah Kantrowitz <noah@coderanger.net>
#
# Copyright 2013, Balanced, Inc.
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

module Poise
  module Resource
    # Provide default_action and actions like LWRPBase but better equipped for subclassing
    module LWRPPolyfill
      module ClassMethods
        def default_action(name=nil)
          if name
            @default_action = name
            actions(name)
          end
          @default_action || ( superclass.respond_to?(:default_action) && superclass.default_action ) || actions.first || :nothing
        end

        def actions(*names)
          @actions ||= ( superclass.respond_to?(:actions) ? superclass.actions.dup : [] )
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
          klass.extend ClassMethods
        end
      end

      extend ClassMethods

      def initialize(*args)
        super
        # Try to not stomp on stuff if already set in a parent
        @action = self.class.default_action if @action == :nothing
        (@allowed_actions << self.class.actions).flatten!.uniq!
      end
    end
  end

  module Provider
    # Helper to handle load_current_resource for direct subclasses of Provider
    module LWRPPolyfill
      module ClassMethods
        def included(klass)
          super
          klass.extend ClassMethods
          if klass.is_a?(Class) && klass.superclass == Chef::Provider
            # Mask Chef::Provider#load_current_resource because it throws NotImplementedError
            klass.class_exec { include Implementation }
          end

          # reinstate the Chef DSL, removed in Chef 12
          klass.class_exec { include Chef::DSL::Recipe }
        end
      end

      module Implementation
        def load_current_resource
        end
      end

      extend ClassMethods
    end
  end
end
