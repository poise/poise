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

require 'poise/helpers/resource_name'


module Poise
  module Helpers
    # A resource mixin to help subclass existing resources.
    #
    # @since 2.3.0
    module ResourceSubclass
      include ResourceName

      module ClassMethods
        def subclass_providers!
          resource_name = self.resource_name
          superclass_resource_name = superclass.resource_name
          # Deal with the node maps.
          node_maps = {}
          node_maps['handler map'] = Chef.provider_handler_map if defined?(Chef.provider_handler_map)
          node_maps['priority map'] = Chef.provider_priority_map if defined?(Chef.provider_priority_map)
          # Patch anything in the descendants tracker.
          Chef::Provider.descendants.each do |provider|
            node_maps["#{provider} node map"] = provider.node_map if defined?(provider.node_map)
          end if defined?(Chef::Provider.descendants)
          node_maps.each do |map_name, node_map|
            map = node_map.respond_to?(:map, true) ? node_map.send(:map) : node_map.instance_variable_get(:@map)
            if map.include?(superclass_resource_name)
              Chef::Log.debug("[#{self}] Copying provider mapping in #{map_name} from #{superclass_resource_name} to #{resource_name}")
              map[resource_name] = map[superclass_resource_name].dup
            end
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
