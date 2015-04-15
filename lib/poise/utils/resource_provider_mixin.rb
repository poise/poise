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


module Poise
  module Utils
    # A mixin to dispatch other mixins with resource and provider
    # implementations. The module this is included in must have Resource and
    # Provider sub-modules.
    #
    # @since 2.0.0
    # @example
    #   module MyHelper
    #     include Poise::Utils::ResourceProviderMixin
    #     module Resource
    #       # ...
    #     end
    #
    #     module Provider
    #       # ...
    #     end
    #   end
    module ResourceProviderMixin
      # @!classmethods
      module ClassMethods
        def included(klass)
          super
          klass.extend(ClassMethods)
          if klass < Chef::Resource
            klass.class_exec { include self::Resource }
          elsif klass < Chef::Provider
            klass.class_exec { include self::Provider }
          end
        end
      end

      extend ClassMethods
    end
  end
end
