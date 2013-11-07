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

class Chef
  class Resource::NotifyingBlockTest < Resource::LWRPBase
    self.resource_name = :notifying_block_test
    default_action(:run)

    attribute(:inner_action, default: :run)
  end

  class Provider::NotifyingBlockTest < Provider::LWRPBase
    include Poise::Provider::NotifyingBlock

    def action_run
      notifying_block do
        ruby_block 'notifying_block_test_inner' do
          action new_resource.inner_action
          block {}
        end
      end
    end
  end
end
