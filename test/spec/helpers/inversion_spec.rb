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

describe Poise::Helpers::Inversion do
  describe Poise::Helpers::Inversion::Resource do
    subject { resource(:poise_test_inversion).new('test', nil) }
    resource(:poise_test_inversion) do
      include described_class
    end

    describe '#options' do
      context 'with no options' do
        it { expect(subject.options).to be_a Mash }
        it { expect(subject.options).to eq({}) }
        it { expect(subject.options(:name)).to be_a Mash }
        it { expect(subject.options(:name)).to eq({}) }
      end # /context with no options

      context 'with all-provider options' do
        before { subject.options(key: 'global') }
        it { expect(subject.options).to be_a Mash }
        it { expect(subject.options).to eq({'key' => 'global'}) }
      end # /context with all-provider options

      context 'with single provider options' do
        before { subject.options(:name, key: 'single') }
        it { expect(subject.options(:name)).to be_a Mash }
        it { expect(subject.options(:name)).to eq({'key' => 'single'}) }
      end # /context with single provider options

      context 'with both options' do
        before do
          subject.options(key: 'global')
          subject.options(:name, key: 'single')
        end
        it { expect(subject.options).to eq({'key' => 'global'}) }
        it { expect(subject.options(:name)).to eq({'key' => 'single'}) }
      end # /context with both options
    end # /describe #options

    describe '#provider' do
      context 'with no provider' do
        its(:provider) { is_expected.to eq nil }
      end # /context with no provider

      context 'with a class provider' do
        before { subject.provider(Object) }
        its(:provider) { is_expected.to eq Object }
      end # /context with a class provider

      context 'with a symbol provider' do
        let(:sentinel) do
          double('provider sentinel', name: '').tap do |s|
            allow(s).to receive(:kind_of?) {|klass| klass == Class }
          end
        end
        before do
          expect(Poise::Helpers::Inversion).to receive(:provider_for).with(:poise_test_inversion, nil, :invert).and_return(sentinel)
          subject.provider(:invert)
        end
        its(:provider) { is_expected.to eq sentinel }
      end # /context with a symbol provider

      context 'with a symbol that is not a provider' do
        before do
          expect(Poise::Helpers::Inversion).to receive(:provider_for).and_return(nil)
          subject.provider(:ruby_block)
        end
        its(:provider) { is_expected.to eq Chef::Provider::RubyBlock }
      end # /context with a symbol that is not a provider
    end # /describe #provider
  end # /decribe Poise::Helpers::Inversion::Resource

  describe Poise::Helpers::Inversion::Provider do
    # Due to internals of the Halite helpers, make sure this is on its own name.
    # Otherwise it can try to run provides? for resources matching the name but
    # in another example.
    subject(:subject_provider) { provider(:poise_test_inversion) }
    provider(:poise_test_inversion) do
      include described_class
      inversion_resource(:poise_test_inversion)
      provides(:inverted)
    end

    describe '.inversion_resource' do
      context 'with a symbol' do
        its(:inversion_resource) { is_expected.to eq :poise_test_inversion }
      end # /context with a symbol

      context 'with a class' do
        provider(:poise_test_inversion) do
          include described_class
          fake_class = Class.new
          def fake_class.resource_name
            :poise_test_inversion
          end
          inversion_resource(fake_class)
        end
        its(:inversion_resource) { is_expected.to eq :poise_test_inversion }
      end # /context with a class
    end # /describe .inversion_resource

    describe '.inversion_attribute' do
      context 'with a string' do
        provider(:poise_test_inversion) do
          include described_class
          inversion_resource(:poise_test_inversion)
          inversion_attribute('string')
        end
        its(:inversion_attribute) { is_expected.to eq %w{string} }
      end # /context with a string

      context 'with an array' do
        provider(:poise_test_inversion) do
          include described_class
          inversion_resource(:poise_test_inversion)
          inversion_attribute([:sym1, :sym2])
        end
        its(:inversion_attribute) { is_expected.to eq %w{sym1 sym2} }
      end # /context with an array
    end # /describe .inversion_attribute

    describe '.resolve_inversion_attribute' do
      context 'with attributes' do
        it do
          expect(subject).to receive(:inversion_attribute).and_return(%w{key1 key2})
          fake_node = {'key1' => {'key2' => 'value'}}
          expect(subject.resolve_inversion_attribute(fake_node)).to eq 'value'
        end
      end # /context with attributes

      context 'with non-existent attributes' do
        it do
          expect(subject).to receive(:inversion_attribute).and_return(%w{key1 key3})
          fake_node = {'key1' => {'key2' => 'value'}}
          expect { subject.resolve_inversion_attribute(fake_node) }.to raise_error(Poise::Error)
        end
      end # /context with non-existent attributes

      context 'with fallback' do
        it do
          expect(subject).to receive(:inversion_attribute).and_return(nil)
          fake_run_context = double('run context')
          fake_node = double('node', run_context: fake_run_context)
          allow(fake_node).to receive(:'[]') {|key| {'key1' => 'value'}[key] }
          expect(subject).to receive(:poise_defined_in_cookbook).with(fake_run_context).and_return('key1')
          expect(subject.resolve_inversion_attribute(fake_node)).to eq 'value'
        end
      end # /context with fallback
    end # /describe .resolve_inversion_attribute

    describe '.inversion_options' do
      let(:attributes) { Hash.new }
      let(:run_state) { Hash.new }
      let(:node) { double('node', run_state: {'poise_inversion' => {poise_test_inversion: run_state}}) }
      let(:new_resource) { double('new_resource', name: 'test', options: {}) }
      subject { subject_provider.inversion_options(node, new_resource) }
      before do
        allow(subject_provider).to receive(:resolve_inversion_attribute).with(node).and_return(attributes)
      end

      context 'defaults' do
        it { is_expected.to eq({}) }
      end # /context defaults

      context 'with global attributes' do
        before do
          attributes['provider'] = 'global'
          attributes['options'] = {key: 'globalval'}
        end
        it { is_expected.to eq({'provider' => 'global', 'key' => 'globalval'}) }
      end # /context with global attributes

      context 'with global run state' do
        before do
          run_state['test'] = {
            '*' => {provider: 'runstate', key: 'runstateval'},
          }
        end
        it { is_expected.to eq({'provider' => 'runstate', 'key' => 'runstateval'}) }
      end # /context with global run state

      context 'with global resource options' do
        before do
          allow(new_resource).to receive(:options).with(no_args).and_return({
            key: 'optionsval',
          })
        end
        it { is_expected.to eq({'key' => 'optionsval'}) }
      end # /context with global resource options

      context 'with specific attributes' do
        before do
          attributes['test'] = {provider: 'specific', key: 'specificval'}
        end
        it { is_expected.to eq({'provider' => 'specific', 'key' => 'specificval'}) }
      end # /context with specific attributes

      context 'with specific run state' do
        before do
          run_state['test'] = {
            'inverted' => {provider: 'runstate', key: 'specficival'},
          }
        end
        it { is_expected.to eq({'provider' => 'runstate', 'key' => 'specficival'}) }
      end # /context with specific run state

      context 'with specific resource options' do
        before do
          allow(new_resource).to receive(:options).with(:inverted).and_return({
            key: 'optionsval',
          })
        end
        it { is_expected.to eq({'key' => 'optionsval'}) }
      end # /context with specific resource options

      context 'with overlapping options' do
        before do
          attributes['provider'] = 'global'
          attributes['options'] = {attrs: 'globalval'}
          attributes['test'] = {attrs: 'specificval'}
          run_state['test'] = {
            '*' => {provider: 'runstate', runstate: 'runstateval'},
            'inverted' => {runstate: 'runstatespecific'},
          }
          allow(new_resource).to receive(:options).with(no_args).and_return({
            resource: 'resourceval',
          })
          allow(new_resource).to receive(:options).with(:inverted).and_return({
            resource: 'resourcespecific',
          })
        end
        it { is_expected.to eq({
          'attrs'=> 'specificval',
          'resource'=> 'resourcespecific',
          'runstate'=> 'runstatespecific',
          'provider'=> 'runstate',
        }) }
      end # /context with overlapping options
    end # /describe .inversion_options

    describe '.resolve_inversion_provider' do
      context 'with no options' do
        it do
          expect(subject).to receive(:inversion_options).and_return({})
          expect(subject.resolve_inversion_provider(nil, nil)).to eq 'auto'
        end
      end # /context with no options

      context 'with a provider' do
        it do
          expect(subject).to receive(:inversion_options).and_return({'provider' => 'invert'})
          expect(subject.resolve_inversion_provider(nil, nil)).to eq 'invert'
        end
      end # /context with a provider
    end # /describe .resolve_inversion_provider
  end # /describe Poise::Helpers::Inversion::Provider
end
