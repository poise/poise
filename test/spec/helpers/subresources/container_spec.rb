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

describe Poise::Helpers::Subresources::Container do
  let(:chefspec_options) { {log_level: :error} } # deprecation spam
  provider(:poise_test)
  resource(:inner)
  provider(:inner)
  # Make sure we run ruby_blocks because of the order fixed magic.
  step_into(:ruby_block)

  context 'with a single subresource' do
    resource(:poise_test) do
      include described_class
    end
    recipe do
      poise_test 'container' do
        inner 'inner'
      end
    end

    it { is_expected.to run_poise_test('container') }
    it { is_expected.to run_inner('container::inner').with(source_line: start_with("#{__FILE__}:33")) }
  end # /context with a single subresource

  context 'with a multiple subresources' do
    resource(:poise_test) do
      include described_class
    end
    recipe do
      poise_test 'container' do
        inner 'inner'
        inner 'inner2'
        inner 'inner3'
      end
    end

    it { is_expected.to run_poise_test('container') }
    it { is_expected.to run_inner('container::inner') }
    it { is_expected.to run_inner('container::inner2') }
    it { is_expected.to run_inner('container::inner3') }
  end # /context with a multiple subresources

  context 'with an explicit namespace' do
    resource(:poise_test) do
      include described_class
      container_namespace('name')
    end
    recipe do
      poise_test 'container' do
        inner 'inner'
      end
    end

    it { is_expected.to run_poise_test('container') }
    it { is_expected.to run_inner('name::inner') }
  end # /context with an explicit namespace

  context 'with an explicit namespace and no inner name' do
    resource(:poise_test) do
      include described_class
      container_namespace('name')
    end
    recipe do
      poise_test 'container' do
        inner ''
      end
    end

    it { is_expected.to run_poise_test('container') }
    it { is_expected.to run_inner('name') }
  end # /context with an explicit namespace and no inner name

  context 'with an explicit Proc namespace' do
    resource(:poise_test) do
      include described_class
      container_namespace(Proc.new { name + '_name' })
    end
    recipe do
      poise_test 'container' do
        inner 'inner'
      end
    end

    it { is_expected.to run_poise_test('container') }
    it { is_expected.to run_inner('container_name::inner') }
  end # /context with an explicit Proc namespace

  context 'with a no namespace' do
    resource(:poise_test) do
      include described_class
      container_namespace(false)
    end
    recipe do
      poise_test 'container' do
        inner 'inner'
      end
    end

    it { is_expected.to run_poise_test('container') }
    it { is_expected.to run_inner('inner') }
  end # /context with a no namespace

  context 'with a no namespace and an empty inner name' do
    resource(:poise_test) do
      include described_class
      container_namespace(false)
    end
    recipe do
      poise_test 'container' do
        inner ''
      end
    end

    it { is_expected.to run_poise_test('container') }
    it { is_expected.to run_inner('container') }
  end # /context with a no namespace and an empty inner name

  context 'with a no namespace and no inner name' do
    resource(:poise_test) do
      include described_class
      container_namespace(false)
    end
    recipe do
      poise_test 'container' do
        inner
      end
    end

    it { is_expected.to run_poise_test('container') }
    it { is_expected.to run_inner('container') }
  end # /context with a no namespace and no inner name

  describe 'resource order' do
    resource(:poise_test) do
      include described_class
    end
    provider(:poise_test) do
      def action_run
        expect(node.run_state['order']).to eq 0
        node.run_state['order'] += 1
      end
    end
    resource(:inner) do
      def val(val=nil)
        set_or_return(:val, val, {})
      end
    end
    provider(:inner) do
      def action_run
        expect(node.run_state['order']).to eq new_resource.val
        node.run_state['order'] += 1
      end
    end
    recipe do
      node.run_state['order'] = 0
      poise_test 'container' do
        inner 'one' do
          val 1
        end
        inner 'two' do
          val 2
        end
      end
    end

    it do
      # The dreaded multi-assertion test. Really I just need to force it to run,
      # these assertions are just additional sanity.
      is_expected.to run_poise_test('container')
      is_expected.to run_inner('container::one')
      is_expected.to run_inner('container::two')
    end
  end # /describe resource order
end
