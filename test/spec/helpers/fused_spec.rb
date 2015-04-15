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

describe Poise::Helpers::Fused do
  resource(:poise_test) do
    include described_class

    action(:run) do
      ruby_block 'inner'
    end
  end
  recipe do
    poise_test 'test'
  end

  it { is_expected.to run_ruby_block('inner') }

  context 'with a nested provider' do
    resource(:poise_test) do
      include described_class

      action(:run) do
        file 'inner' do
          content new_resource.name
        end
      end
    end

    it { is_expected.to create_file('inner').with(content: 'test') }
  end # /context with a nested provider

  context 'with a subclass' do
    resource(:poise_test2, parent: :poise_test) do
      action(:run) do
        super()
        ruby_block 'inner2'
      end
    end
    recipe do
      poise_test2 'test'
    end

    it { is_expected.to run_ruby_block('inner') }
    it { is_expected.to run_ruby_block('inner2') }
  end # /context with a subclass

  context 'with setting a default action' do
    resource(:poise_test) do
      include described_class
      include Poise::Helpers::LWRPPolyfill

      action(:install) do
        ruby_block 'inner'
      end
    end

    it { is_expected.to install_poise_test('test') }
    it { is_expected.to run_ruby_block('inner') }
  end # /context with setting a default action

  context 'with an explicit provider' do
    provider(:poise_test2) do
      include Poise
      def action_run
        ruby_block 'explicit'
      end
    end
    recipe do
      poise_test 'test' do
        provider :poise_test2
      end
    end

    it { is_expected.to run_ruby_block('explicit') }
    it { is_expected.to_not run_ruby_block('inner') }
  end # /context with an explicit provider
end
