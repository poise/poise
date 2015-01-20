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

require 'spec_helper'

describe Poise::SubContextBlock do
  resource(:poise_test)
  recipe do
    poise_test 'test'
  end

  # General sanity test
  provider(:poise_test) do
    include Poise::SubContextBlock
    include Chef::DSL::Recipe

    def action_run
      top_level_collection = run_context.resource_collection
      sub = subcontext_block do
        expect(run_context.resource_collection).to_not be top_level_collection
        expect(global_resource_collection).to be top_level_collection
        expect(run_context.resource_collection.parent).to be top_level_collection

        ruby_block 'inner'
      end
      expect(sub.resource_collection.find('ruby_block[inner]')).to be_truthy
    end
  end

  it { is_expected.to_not run_ruby_block('inner') }

  # Make sure the .parent forwarding works
  describe '#global_resource_collection' do
    provider(:poise_test) do
      include Poise::SubContextBlock
      include Chef::DSL::Recipe

      def action_run
        top_level_collection = run_context.resource_collection
        subcontext_block do
          subcontext_block do
            expect(global_resource_collection).to be top_level_collection
          end
        end
      end
    end

    it { subject }
  end
end
