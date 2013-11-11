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
    module LWRPPolyfill
      module ClassMethods
        def default_action(name)
        end

        def actions(*names)
        end

        def included(klass)
          super
          klass.extend ClassMethods
        end

        extend ClassMethods

        def initialize(*args)
          super
        end

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
          # Warning: relatively brittle check if this class has a real impl :-(
          # This has to handle the simple case of inheriting from Provider, but
          # also subclassing existing providers and possible LWRPBase.
          loc = klass.instance_method(:load_current_resource).source_location[0]
          if loc.end_with?(::File.join('', 'lib', 'chef', 'provider.rb'))
            # Probably the original one, mask it to prevent errors
            klass.define_method(:load_current_resource) {}
          end
        end
      end

      extend ClassMethods
    end
  end
end
