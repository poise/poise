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

describe Poise::Helpers::Inversion::OptionsResource do
  let(:default_attributes) do
    {'poise-test' => {}}
  end
  resource(:poise_test_options) do
    include described_class
    inversion_resource(:poise_test_inversion)
  end
  provider(:poise_test_options)

  describe '#_options' do
    context 'with simple options' do
      recipe do
        poise_test_options 'test' do
          foo 'bar'
          baz 42
        end
      end

      it { is_expected.to run_poise_test_options('test').with(_options: {'foo' => 'bar', 'baz' => 42}) }
    end # /context with simple options

    context 'with node options' do
      recipe do
        poise_test_options 'test' do
          foo 'bar'
          baz node.name
        end
      end

      it { is_expected.to run_poise_test_options('test').with(_options: {'foo' => 'bar', 'baz' => 'chefspec.local'}) }
    end # /context with node options

    context 'with new_resource-based options' do
      resource(:poise_test) do
        def foo(val=nil)
          set_or_return(:foo, val, {})
        end
      end
      provider(:poise_test) do
        include Chef::DSL::Recipe
        def action_run
          poise_test_options new_resource.name do
            foo new_resource.foo
          end
        end
      end
      recipe do
        poise_test 'test' do
          foo 'bar'
        end
      end

      it { is_expected.to run_poise_test_options('test').with(_options: {'foo' => 'bar'}) }
    end # /context with new_resource-based options

    context 'with a bad method' do
      recipe do
        poise_test_options 'test' do
          foo noode.name
          baz 42
        end
      end

      it { expect { subject }.to raise_error NoMethodError }
    end # /context with a bad method

    context 'with derived options' do
      recipe do
        poise_test_options 'test' do
          foo node.name
          baz foo + 'a'
        end
      end

      it { is_expected.to run_poise_test_options('test').with(_options: {'foo' => 'chefspec.local', 'baz' => 'chefspec.locala'}) }
    end # /context with derived options
  end # /describe #_options

  describe 'provider options' do
    resource(:poise_test_inversion) do
      include Poise::Helpers::Inversion::Resource
    end
    provider(:poise_test_inversion_one) do
      include Poise::Helpers::Inversion::Provider
      inversion_resource(:poise_test_inversion)
      inversion_attribute('poise-test')
      provides(:poise_test_inversion)
      def self.provides_auto?(node, resource)
        true
      end
    end
    subject do
      chef_run.poise_test_inversion('test').provider_for_action(:nothing).options
    end

    context 'before service resource' do
      recipe(subject: false) do
        poise_test_options 'test' do
          position 'before'
        end

        poise_test_inversion 'test'
      end

      it { is_expected.to eq({'position' => 'before'}) }
    end # /context before service resource

    context 'after service resource' do
      recipe(subject: false) do
        poise_test_inversion 'test'

        poise_test_options 'test' do
          position 'after'
        end
      end

      it { is_expected.to eq({'position' => 'after'}) }
    end # /context after service resource

    # This is a regression test because the poise-service version couldn't
    # do this combination.
    context 'before service resource for a provider' do
      recipe(subject: false) do
        poise_test_options 'test' do
          for_provider :poise_test_inversion
          position 'before'
        end

        poise_test_inversion 'test'
      end

      it { is_expected.to eq({'position' => 'before'}) }
    end # /context before service resource for a provider

    context 'after service resource for a provider' do
      recipe(subject: false) do
        poise_test_inversion 'test'

        poise_test_options 'test' do
          for_provider :poise_test_inversion
          position 'after'
        end
      end

      it { is_expected.to eq({'position' => 'after'}) }
    end # /context after service resource for a provider

    context 'after service resource for a non-matching provider' do
      recipe(subject: false) do
        poise_test_inversion 'test'

        poise_test_options 'test' do
          for_provider :other
          position 'after'
        end
      end

      it { is_expected.to eq({}) }
    end # /context after service resource for a non-matching provider

    context 'mutiple options' do
      recipe(subject: false) do
        poise_test_options 'test1' do
          resource 'test'
          position 'before'
          one 1
        end

        poise_test_inversion 'test'

        poise_test_options 'test2' do
          resource 'test'
          for_provider :poise_test_inversion
          two 2
        end

        poise_test_options 'test3' do
          resource 'test'
          position 'after'
          three 3
        end

        poise_test_options 'test4' do
          resource 'test'
          for_provider :other
          four 4
        end
      end

      it { is_expected.to eq({'position' => 'after', 'one' => 1, 'two' => 2, 'three' => 3}) }
    end # /context mutiple options
  end # /describe provider options
end
