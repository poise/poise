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

require 'poise'


module PoiseTest
  module Inversion
    class Resource < Chef::Resource
      include Poise(inversion: true)
      provides(:poise_test_inversion)
      actions(:run)

      attribute(:path, name_attribute: true)
    end

    class ProviderOne < Chef::Provider
      include Poise(inversion: Resource)
      provides(:one)

      def self.provides_auto?(node, resource)
        true
      end

      def action_run
        file new_resource.path do
          content 'one'
        end
      end
    end

    class ProviderTwo < Chef::Provider
      include Poise(inversion: Resource)
      provides(:two)

      def action_run
        file new_resource.path do
          content 'two'
        end
      end
    end

    class ProviderThree < Chef::Provider
      include Poise(inversion: Resource)
      provides(:three)

      def action_run
        file new_resource.path do
          content options['msg'] || 'three'
        end
      end
    end
  end
end
