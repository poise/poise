#
# Author:: Noah Kantrowitz <noah@coderanger.net>
#
# Copyright 2013-2014, Noah Kantrowitz
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
  class Resource::SubcontextBlockTestOne < Resource
    def initialize(*args)
      super
      @resource_name = :subcontext_block_test_one
      @action = :run
    end
  end

  class Provider::SubcontextBlockTestOne < Provider
    include Poise::SubContextBlock
    include Chef::DSL::Recipe

    def load_current_resource
    end

    def action_run
      run_state = node.run_state
      subcontext_block do
        run_state[:subcontext_block_test_collection] = run_context.resource_collection
        run_state[:subcontext_block_test_global_collection] = global_resource_collection
        ruby_block 'subcontext_block_test_inner' do
          block do
            run_state[:subcontext_block_test_inner] = true
          end
        end
      end
    end
  end
end
