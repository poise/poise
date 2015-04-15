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

require 'spec_helper'

describe Poise::Helpers::NotifyingBlock do
  before { step_into << 'ruby_block' }
  resource(:poise_test, unwrap_notifying_block: false) do
    def inner_action(val=nil)
      set_or_return(:inner_action, val, {})
    end
  end
  provider(:poise_test) do
    include Poise::Helpers::LWRPPolyfill
    include described_class

    def action_run
      notifying_block do
        ruby_block 'inner' do
          action new_resource.inner_action
          block { }
        end
      end
    end
  end

  context 'with updated inner resources' do
    recipe do
      poise_test 'test' do
        inner_action :run
      end
    end

    it 'marks the outer resource as updated' do
      expect(subject.find_resource('poise_test', 'test').updated_by_last_action?).to be_truthy
    end

    it 'does not add the inner resource to the global collection' do
      expect(subject.find_resource('ruby_block', 'inner ')).to be_nil
    end
  end # /context with updated inner resources

  context 'without updated inner resources' do
    recipe do
      poise_test 'test' do
        inner_action :nothing
      end
    end

    it 'does not marks the outer resource as updated' do
      expect(subject.find_resource('poise_test', 'test').updated_by_last_action?).to be_falsey
    end
  end # /context without updated inner resources

  context 'with an exception raised inside the block' do
    provider(:poise_test) do
      include Poise::Helpers::LWRPPolyfill
      include described_class

      def action_run
        notifying_block do
          ruby_block 'inner' do
            block { raise 'Boom!' }
          end
        end
      end
    end
    recipe do
      poise_test 'test'
    end

    it { expect { subject }.to raise_error(RuntimeError) }
  end # /context with an exception raised inside the block
end
