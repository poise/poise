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
require 'chef/provider/lwrp_base'
require 'chef/resource/lwrp_base'

describe Poise::Helpers::LWRPPolyfill do
  describe Poise::Helpers::LWRPPolyfill::Resource do
    describe '#attribute' do
      resource(:poise_test) do
        include described_class
        attribute(:boolean, equal_to: [true, false])
      end
      provider(:poise_test)
      recipe do
        poise_test 'test'
      end

      context 'with no value' do
        it { is_expected.to run_poise_test('test').with(boolean: nil) }
      end # /context with no value

      context 'with a true value' do
        recipe do
          poise_test 'test' do
            boolean true
          end
        end

        it { is_expected.to run_poise_test('test').with(boolean: true) }
      end # /context with a true value

      context 'with a false value' do
        recipe do
          poise_test 'test' do
            boolean false
          end
        end

        it { is_expected.to run_poise_test('test').with(boolean: false) }
      end # /context with a false value

      context 'with a string value' do
        recipe do
          poise_test 'true' do
            boolean 'boom'
          end
        end

        it { expect { subject }.to raise_error Chef::Exceptions::ValidationFailed }
      end # /context with a string value

      context 'with a default value' do
        resource(:poise_test) do
          include described_class
          attribute(:value, default: 'default value')
        end

        it { is_expected.to run_poise_test('test').with(value: 'default value') }
      end # /context with a default value

      context 'with a mutable default value' do
        resource(:poise_test) do
          include described_class
          attribute(:value, default: [])
        end

        it { is_expected.to run_poise_test('test').with(value: []) }
        it { expect(chef_run.poise_test('test').value).to be_frozen }

        context 'and trying to change it' do
          recipe do
            poise_test 'test' do
              value << 1
            end
          end

          it { expect { chef_run }.to raise_error RuntimeError }
        end # /context and trying to change it
      end # /context with a mutable default value
    end # /describe #attribute

    describe '#default_action' do
      resource(:poise_test) do
        include described_class
        default_action(:one)
        actions(:two)
      end
      provider(:poise_test) do
        def action_one; end
        def action_two; end
      end
      recipe do
        poise_test 'test'
      end

      it { is_expected.to one_poise_test('test') }
      it { expect(resource(:poise_test).default_action).to eq [:one] }
    end # /describe #default_action
  end # /describe Poise::Helpers::LWRPPolyfill::Resource

  describe Poise::Helpers::LWRPPolyfill::Provider do
    describe 'load_current_resource override' do
      resource(:poise_test)
      let(:test_resource) { resource(:poise_test).new('test', nil) }
      subject { provider(:poise_test).new(test_resource, nil).load_current_resource }

      context 'with a direct Provider subclass' do
        provider(:poise_test, auto: false) do
          include described_class
        end

        it { is_expected.to be_a resource(:poise_test) }
        its(:name) { is_expected.to eq 'test' }
      end # /context with a direct Provider subclass

      context 'with an intermediary class' do
        provider(:poise_parent, auto: false) do
          def load_current_resource
            @current_resource = 'helper'
          end
        end
        provider(:poise_test, auto: false, parent: :poise_parent) do
          include described_class
        end

        it { is_expected.to eq 'helper' }
      end # /context with an intermediary class

      context 'calling super' do
        provider(:poise_test, auto: false) do
          include described_class
          def load_current_resource
            super.tap do |current_resource|
              current_resource.name('other')
            end
          end
        end
        its(:name) { is_expected.to eq 'other' }
      end # /context calling super
    end # /describe load_current_resource override

    describe 'Chef::DSL::Recipe include' do
      resource(:poise_test)
      provider(:poise_test) do
        include described_class

        def action_run
          ruby_block 'test'
        end
      end
      recipe do
        poise_test 'test'
      end

      it { is_expected.to run_ruby_block('test') }
    end # /describe Chef::DSL::Recipe include
  end # /describe Poise::Helpers::LWRPPolyfill::Provider

  context 'inside LWRPBase' do
    resource(:poise_test, parent: Chef::Resource::LWRPBase, auto: false) do
      include described_class
      actions(:run)
    end
    provider(:poise_test, parent: Chef::Provider::LWRPBase, auto: false) do
      include described_class
      action(:run) { }
    end

    describe '#default_action' do
      subject { resource(:poise_test).default_action }
      it { is_expected.to eq %i{run} }
    end # /describe #default_action
  end # /context inside LWRPBase
end
