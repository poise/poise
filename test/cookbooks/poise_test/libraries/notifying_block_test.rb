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
  # Simple test with one internal resource
  class Resource::NotifyingBlockTestOne < Resource
    def initialize(*args)
      super
      @resource_name = :notifying_block_test_one
      @action = :run
    end

    def inner_action(arg=nil)
      set_or_return(:inner_action, arg, default: :run)
    end
  end

  class Provider::NotifyingBlockTestOne < Provider
    include Poise::Provider::NotifyingBlock

    def load_current_resource
    end

    def action_run
      notifying_block do
        ruby_block 'notifying_block_test_inner' do
          action new_resource.inner_action
          block {}
        end
      end
    end
  end

  # Test with two internal resources
  class Resource::NotifyingBlockTestTwo < Resource
    def initialize(*args)
      super
      @resource_name = :notifying_block_test_two
      @action = :run
    end

    def inner_action_one(arg=nil)
      set_or_return(:inner_action_one, arg, default: :run)
    end

    def inner_action_two(arg=nil)
      set_or_return(:inner_action_two, arg, default: :run)
    end
  end

  class Provider::NotifyingBlockTestTwo < Provider
    include Poise::Provider::NotifyingBlock

    def load_current_resource
    end

    def action_run
      notifying_block do
        ruby_block 'notifying_block_test_inner_one' do
          action new_resource.inner_action_one
          block {}
        end

        ruby_block 'notifying_block_test_inner_two' do
          action new_resource.inner_action_two
          block {}
        end
      end
    end
  end
end
