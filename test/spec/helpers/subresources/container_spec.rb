#
# Copyright 2015-2016, Noah Kantrowitz
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

  describe '#container_default' do
    resource(:poise_test) do
      include described_class
    end
    resource(:poise_sub, parent: :poise_test) do
      container_default(false)
    end
    provider(:poise_sub, parent: :poise_test)
    resource(:inner) do
      include Poise(parent: :poise_test)
    end
    recipe do
      poise_test 'one'
      poise_test 'two'
      poise_sub 'three'
      inner 'inner'
    end

    it { is_expected.to run_inner('inner').with(parent: chef_run.poise_test('two')) }
  end # /describe #container_default

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

  describe 'subclassing a container' do
    resource(:poise_test) do
      include described_class
    end
    resource(:poise_sub, parent: :poise_test)
    provider(:poise_sub, parent: :poise_test)
    recipe do
      poise_sub 'test' do
        inner 'one'
      end
    end

    it { is_expected.to run_poise_sub('test') }
    it { is_expected.to run_inner('test::one') }
  end # /describe subclassing a container

  describe 'triple nesting' do
    resource(:poise_grandparent) do
      include described_class
      attr_accessor :order
    end
    provider(:poise_grandparent) do
      def action_run
        new_resource.order = (node.run_state[:order] += 1)
      end
    end
    resource(:poise_parent) do
      include described_class
      include Poise::Helpers::Subresources::Child
      parent_type :poise_grandparent
      attr_accessor :order
    end
    provider(:poise_parent) do
      def action_run
        new_resource.order = (node.run_state[:order] += 1)
      end
    end
    resource(:poise_child) do
      include described_class
      include Poise::Helpers::Subresources::Child
      parent_type :poise_parent
      attr_accessor :order
    end
    provider(:poise_child) do
      def action_run
        new_resource.order = (node.run_state[:order] += 1)
      end
    end

    context 'nested' do
      recipe do
        node.run_state[:order] = 0
        poise_grandparent 'one' do
          poise_parent 'two' do
            poise_child 'three'
          end
        end
      end

      it { is_expected.to run_poise_grandparent('one').with(order: 1) }
      it { is_expected.to run_poise_parent('one::two').with(parent: chef_run.poise_grandparent('one'), order: 2) }
      it { is_expected.to run_poise_child('one::two::three').with(parent: chef_run.poise_parent('one::two'), order: 3) }
    end # /context nested

    context 'un-nested' do
      recipe do
        node.run_state[:order] = 0
        poise_grandparent 'one'
        poise_parent 'two'
        poise_child 'three'
      end

      it { is_expected.to run_poise_grandparent('one').with(order: 1) }
      it { is_expected.to run_poise_parent('two').with(parent: chef_run.poise_grandparent('one'), order: 2) }
      it { is_expected.to run_poise_child('three').with(parent: chef_run.poise_parent('two'), order: 3) }
    end # /context un-nested
  end # /describe triple nesting

  describe 'subresources with notifications' do
    step_into(:ruby_block)
    resource(:poise_parent) do
      include described_class
    end
    provider(:poise_parent)
    resource(:poise_child) do
      include Poise::Helpers::Subresources::Child
      parent_type :poise_parent
    end
    provider(:poise_child) do
      def action_run
        new_resource.updated_by_last_action(true)
      end
    end
    subject { chef_run.node.run_state['poise_notified'] }

    context 'delayed notification' do
      recipe(subject: false) do
        ruby_block 'one' do
          action :nothing
          block { node.run_state['poise_notified'] = true }
        end
        poise_parent 'two' do
          poise_child 'three' do
            notifies :run, 'ruby_block[one]', :delayed
          end
        end
      end

      it { is_expected.to be true }
    end # /context delayed notification

    context 'immediate notification' do
      recipe(subject: false) do
        ruby_block 'one' do
          action :nothing
          block { node.run_state['poise_notified'] = true }
        end
        poise_parent 'two' do
          poise_child 'three' do
            notifies :run, 'ruby_block[one]', :immediately
          end
        end
      end

      it { is_expected.to be true }
    end # /context immediate notification
  end # /describe subresources with notifications
end
