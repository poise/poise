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

describe Poise::Helpers::Subresources::Child do
  resource(:poise_container) do
    include Poise::Helpers::ResourceName
    include Poise::Helpers::Subresources::Container
  end
  provider(:poise_container)
  provider(:poise_test)

  describe '#parent' do
    let(:container) { chef_run.poise_container('test') }
    resource(:poise_test) do
      include described_class
      parent_type :poise_container
    end

    context 'with an automatic parent' do
      recipe do
        poise_container 'test'
        poise_test 'test'
      end

      it { is_expected.to run_poise_test('test').with(parent: container) }
    end # /context with an automatic parent

    context 'with an automatic parent and an extra container' do
      recipe do
        poise_container 'test'
        poise_test 'test'
        poise_container 'other'
      end

      it { is_expected.to run_poise_test('test').with(parent: container) }
    end # /context with an automatic parent and an extra container

    context 'with a resource parent' do
      recipe do
        c = poise_container 'test'
        poise_test 'test' do
          parent c
        end
      end

      it { is_expected.to run_poise_test('test').with(parent: container) }
    end # /context with a resource parent

    context 'with a resource parent and an extra container' do
      recipe do
        c = poise_container 'test'
        poise_container 'other'
        poise_test 'test' do
          parent c
        end
      end

      it { is_expected.to run_poise_test('test').with(parent: container) }
    end # /context with a resource parent and an extra container

    context 'with a string name parent' do
      recipe do
        poise_container 'test'
        poise_test 'test' do
          parent 'test'
        end
      end

      it { is_expected.to run_poise_test('test').with(parent: container) }
    end # /context with a string name parent

    context 'with an explicit string parent' do
      recipe do
        poise_container 'test'
        poise_test 'test' do
          parent 'poise_container[test]'
        end
      end

      it { is_expected.to run_poise_test('test').with(parent: container) }
    end # /context with an explicit string parent

    context 'with a hash parent' do
      recipe do
        poise_container 'test'
        poise_test 'test' do
          parent poise_container: 'test'
        end
      end

      it { is_expected.to run_poise_test('test').with(parent: container) }
    end # /context with a hash parent

    context 'with a parent of the wrong type' do
      recipe do
        ruby_block 'test'
        poise_test 'test' do
          parent 'ruby_block[test]'
        end
      end

      it { expect { subject }.to raise_error Poise::Error }
    end # /context with a parent of the wrong type

    context 'with a sibling parent' do
      recipe do
        poise_container 'test'
        poise_test 'test'
      end

      it { is_expected.to run_poise_test('test').with(parent: container) }
    end # /context with a sibling parent

    context 'with no parent' do
      recipe do
        poise_test 'test'
      end

      it { expect { subject }.to raise_error Poise::Error }
    end # /context with no parent

    context 'with an optional parent' do
      resource(:poise_test) do
        include described_class
        parent_type :poise_container
        parent_optional true
      end
      recipe do
        poise_test 'test'
      end

      it { is_expected.to run_poise_test('test').with(parent: nil) }
    end # /context with an optional parent

    context 'with a default parent in a nested scope' do
      resource(:poise_wrapper, unwrap_notifying_block: false) do
        include Poise::Helpers::ResourceName
        include Poise::Helpers::Subresources::Container
      end
      provider(:poise_wrapper) do
        include Poise::Helpers::LWRPPolyfill
        include Poise::Helpers::NotifyingBlock
        def action_run
          notifying_block do
            poise_container new_resource.name
          end
        end
      end
      recipe do
        poise_wrapper 'wrapper' do
          action :nothing
        end.run_action(:run)
        poise_test 'test'
      end

      it { is_expected.to run_poise_test('test').with(parent: be_truthy) }
      it { expect(chef_run.poise_container('wrapper')).to be_nil }
    end # /context with a default parent in a nested scope

    context 'with no automatic parent' do
      resource(:poise_test) do
        include described_class
        parent_type :poise_container
        parent_auto false
      end
      recipe do
        poise_container 'test'
        poise_test 'test'
      end

      it { expect { run_chef }.to raise_error(Poise::Error) }
    end # /context with no automatic parent

    context 'with no automatic parent but optional' do
      resource(:poise_test) do
        include described_class
        parent_type :poise_container
        parent_optional true
        parent_auto false
      end
      recipe do
        poise_container 'test'
        poise_test 'test'
      end

      it { is_expected.to run_poise_test('test').with(parent: be_nil) }
    end # /context with no automatic parent but optional

    context 'with a parent but then unset' do
      recipe do
        poise_container 'test2'
        poise_container 'test'
        poise_test 'test' do
          parent 'test2'
          parent nil
        end
      end

      it { is_expected.to run_poise_test('test').with(parent: container) }
    end # context with a parent but then unset

    context 'with an optional parent but then unset' do
      resource(:poise_test) do
        include described_class
        parent_type :poise_container
        parent_optional true
        parent_auto false
      end
      recipe do
        poise_container 'test'
        poise_test 'test' do
          parent 'test'
          parent nil
        end
      end

      it { is_expected.to run_poise_test('test').with(parent: nil) }
    end # context with an optional parent but then unset

    context 'with a parent type of true' do
      resource(:poise_test) do
        include described_class
        parent_type true
      end
      recipe do
        poise_test 'test' do
          parent 'test'
        end
      end

      it { expect { subject }.to raise_error NoMethodError }
    end # /context with a parent type of true

    context 'with a subclassed parent type' do
      resource(:poise_sub, parent: :poise_container)
      provider(:poise_sub, parent: :poise_container)
      let(:sub) { chef_run.poise_sub('test') }

      context 'with an automatic parent' do
        recipe do
          poise_sub 'test'
          poise_test 'test'
        end

        it { is_expected.to run_poise_test('test').with(parent: sub) }
      end # /context with an automatic parent

      context 'with a resource parent' do
        recipe do
          c = poise_sub 'test'
          poise_test 'test' do
            parent c
          end
        end

        it { is_expected.to run_poise_test('test').with(parent: sub) }
      end # /context with a resource parent

      context 'with a string name parent' do
        recipe do
          poise_sub 'test'
          poise_test 'test' do
            parent 'test'
          end
        end

        it { is_expected.to run_poise_test('test').with(parent: sub) }
      end # /context with a string name parent

      context 'with an explicit string parent' do
        recipe do
          poise_sub 'test'
          poise_test 'test' do
            parent 'poise_sub[test]'
          end
        end

        it { is_expected.to run_poise_test('test').with(parent: sub) }
      end # /context with an explicit string parent

      context 'with a hash parent' do
        recipe do
          poise_sub 'test'
          poise_test 'test' do
            parent poise_sub: 'test'
          end
        end

        it { is_expected.to run_poise_test('test').with(parent: sub) }
      end # /context with a hash parent
    end # /context with a subclassed parent type

    context 'with a default' do
      resource(:poise_test) do
        include described_class
        parent_type :poise_container
        parent_default Chef::DelayedEvaluator.new { run_context.resource_collection.find('poise_container[first]') }
      end
      recipe do
        poise_container 'first'
        poise_container 'second'
        poise_test 'test'
      end

      it { is_expected.to run_poise_test('test').with(parent: chef_run.poise_container('first')) }
    end # /context with a default

    context 'setting the parent to itself' do
      resource(:poise_test) do
        include described_class
        parent_type :poise_test
      end
      recipe do
        poise_test 'test' do
          parent self
        end
      end

      it { expect { subject }.to raise_error Poise::Error }
    end # /context setting the parent to itself

    context 'when possibly setting to self via default' do
      resource(:poise_test) do
        include described_class
        include Poise::Helpers::ResourceName
        include Poise::Helpers::Subresources::Container
        parent_type :poise_test
        parent_optional true
      end
      recipe do
        poise_test 'one'
        poise_test 'two'
      end

      it { is_expected.to run_poise_test('one').with(parent: nil) }
      it { is_expected.to run_poise_test('two').with(parent: chef_run.poise_test('one')) }
    end # /context when possibly setting to self via default
  end # /describe #parent

  describe '.parent_type' do
    subject { resource(:poise_test).parent_type }

    context 'set directly' do
      resource(:poise_test) do
        include described_class
        parent_type String
      end

      it { is_expected.to eq String }
    end # /context set directly

    context 'set on a parent class' do
      resource(:poise_parent) do
        include described_class
        parent_type String
      end
      resource(:poise_test, parent: :poise_parent)

      it { is_expected.to eq String }
    end # /context set on a parent class

    context 'not set' do
      resource(:poise_test) do
        include described_class
      end

      it { is_expected.to eq Chef::Resource }
    end # /context not set

    context 'set to a symbol' do
      resource(:poise_test) do
        include described_class
        parent_type :something
      end

      it { is_expected.to eq :something }
    end # /context set to a symbol

    context 'set to true' do
      resource(:poise_test) do
        include described_class
        parent_type true
      end

      it { is_expected.to eq true }
    end # /context set to true

    context 'set to an invalid value' do
      resource(:poise_test) do
        include described_class
      end

      it do
        expect { resource(:poise_test).parent_type('invalid') }.to raise_error Poise::Error
      end
    end # /context set to an invalid value

    context 'set directly and then set to true' do
      resource(:poise_test) do
        include described_class
        parent_type String
        parent_type true
      end

      it { is_expected.to eq String }
    end # /context set directly and then set to true

    context 'set via a mixin' do
      # Various scoping shenanigans.
      described = described_class
      test_mod = Module.new do
        include described
        parent_type :something
      end
      resource(:poise_test) do
        include test_mod
      end

      it { is_expected.to eq :something }
    end # /context set via a mixin

    context 'set to true via a mixin' do
      # Various scoping shenanigans.
      described = described_class
      test_mod = Module.new do
        include described
        parent_type true
      end
      resource(:poise_test) do
        include test_mod
      end

      it { is_expected.to eq true }
    end # /context set to true via a mixin

    context 'set via multiple mixins' do
      # Various scoping shenanigans.
      described = described_class
      test_mod1 = Module.new do
        include described
        parent_type :something
      end
      test_mod2 = Module.new do
        include described
        parent_type true
      end
      resource(:poise_test) do
        include test_mod1
        include test_mod2
      end

      it { is_expected.to eq :something }
    end # context set via multiple mixins
  end # /describe .parent_type

  describe '.parent_optional' do
    subject { resource(:poise_test).parent_optional }

    context 'set directly' do
      resource(:poise_test) do
        include described_class
        parent_optional true
      end

      it { is_expected.to eq true }
    end # /context set directly

    context 'set on a parent class' do
      resource(:poise_parent) do
        include described_class
        parent_optional true
      end
      resource(:poise_test, parent: :poise_parent)

      it { is_expected.to eq true }
    end # /context set on a parent class

    context 'not set' do
      resource(:poise_test) do
        include described_class
      end

      it { is_expected.to eq false }
    end # /context not set
  end # /describe .parent_optional

  describe '.parent_auto' do
    subject { resource(:poise_test).parent_auto }

    context 'set directly' do
      resource(:poise_test) do
        include described_class
        parent_auto true
      end

      it { is_expected.to eq true }
    end # /context set directly

    context 'set on a parent class' do
      resource(:poise_parent) do
        include described_class
        parent_auto true
      end
      resource(:poise_test, parent: :poise_parent)

      it { is_expected.to eq true }
    end # /context set on a parent class

    context 'not set' do
      resource(:poise_test) do
        include described_class
      end

      it { is_expected.to eq true }
    end # /context not set
  end # /describe .parent_auto

  describe '.parent_default' do
    subject { resource(:poise_test).parent_default }

    context 'set directly' do
      resource(:poise_test) do
        include described_class
        parent_default Chef::Resource.new(nil, nil)
      end

      it { is_expected.to be_a Chef::Resource }
    end # /context set directly

    context 'set on a parent class' do
      resource(:poise_parent) do
        include described_class
        parent_default Chef::Resource.new(nil, nil)
      end
      resource(:poise_test, parent: :poise_parent)

      it { is_expected.to be_a Chef::Resource }
    end # /context set on a parent class

    context 'not set' do
      resource(:poise_test) do
        include described_class
      end

      it { is_expected.to be_nil }
    end # /context not set

    context 'set to nil' do
      resource(:poise_parent) do
        include described_class
        parent_default Chef::Resource.new(nil, nil)
      end
      resource(:poise_test, parent: :poise_parent) do
        parent_default nil
      end

      it { is_expected.to be_nil }
    end # /context set to nil

    context 'set to lazy{}' do
      resource(:poise_test) do
        include described_class
        include Poise::Helpers::LazyDefault
        parent_default lazy { }
      end

      it { is_expected.to be_a Chef::DelayedEvaluator }
    end # /context set to lazy{}
  end # /describe .parent_default

  describe '.parent_attribute' do
    resource(:poise_test) do
      include described_class
      parent_type :poise_container
      parent_attribute :other, type: :poise_container
    end
    recipe do
      poise_container 'one'
      poise_container 'two'
      poise_test 'test' do
        parent_other 'one'
      end
    end

    it do
      is_expected.to run_poise_test('test').with(
        parent: chef_run.poise_container('two'),
        parent_other: chef_run.poise_container('one'),
      )
    end
  end # /describe .parent_attribute

  describe 'ParentRef' do
    subject { chef_run.poise_test('two').to_text }

    context 'with a parent' do
      resource(:poise_test) do
        include described_class
        parent_type :poise_container
      end
      recipe(subject: false) do
        poise_container 'one'
        poise_test 'two'
      end

      it { is_expected.to include 'parent poise_container[one]' }
      # Negative test for the Resource#to_text format.
      it { is_expected.to_not include 'poise_container("one")' }
    end # /context with a parent

    context 'without a parent' do
      resource(:poise_test) do
        include described_class
        parent_type :poise_container
        parent_optional true
      end
      recipe(subject: false) do
        poise_test 'two'
      end

      it { is_expected.to include 'parent nil' }
    end # /context without a parent
  end # /describe ParentRef

  describe 'regression test for ordering bug' do
    resource(:poise_test) do
      include Poise
      include Module.new {
        include Poise::Resource
        poise_subresource(true)
        parent_attribute(:container, type: :poise_container, optional: true)
      }
    end
    recipe do
      poise_container 'one'
      poise_test 'test'
      poise_container 'two'
    end

    it { is_expected.to run_poise_test('test').with(parent_container: chef_run.poise_container('one')) }
  end # /describe regression test for ordering bug
end
