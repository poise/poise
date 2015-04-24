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

    context 'with a resource parent' do
      recipe do
        c = poise_container 'test'
        poise_test 'test' do
          parent c
        end
      end

      it { is_expected.to run_poise_test('test').with(parent: container) }
    end # /context with a resource parent

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

    context 'set to an invalid value' do
      resource(:poise_test) do
        include described_class
      end

      it do
        expect { resource(:poise_test).parent_type('invalid') }.to raise_error Poise::Error
      end
    end # /context set to an invalid value
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
  end

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
end
