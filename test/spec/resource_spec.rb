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

describe Poise::Resource do
  resource(:poise_test) do
    include described_class
  end
  subject { resource(:poise_test) }

  it { is_expected.to include Poise::Helpers::LazyDefault }
  it { is_expected.to include Poise::Helpers::LWRPPolyfill }
  it { is_expected.to include Poise::Helpers::OptionCollector }
  it { is_expected.to include Poise::Helpers::ResourceName }
  it { is_expected.to include Poise::Helpers::TemplateContent }
  it { is_expected.to include Poise::Helpers::ChefspecMatchers }

  describe '#poise_subresource_container' do
    resource(:poise_test) do
      include described_class
      poise_subresource_container
    end

    it { is_expected.to include Poise::Helpers::Subresources::Container }
  end # /describe #poise_subresource_container

  describe '#poise_subresource' do
    context 'with no arguments' do
      resource(:poise_test) do
        include described_class
        poise_subresource
      end

      it { is_expected.to include Poise::Helpers::Subresources::Child }
      its(:parent_type) { is_expected.to eq Chef::Resource }
      its(:parent_optional) { is_expected.to be_falsey }
    end # /context with no arguments

    context 'with a parent class' do
      resource(:poise_test) do
        include described_class
        poise_subresource(Chef::Resource::RubyBlock)
      end

      it { is_expected.to include Poise::Helpers::Subresources::Child }
      its(:parent_type) { is_expected.to eq Chef::Resource::RubyBlock }
      its(:parent_optional) { is_expected.to be_falsey }
    end # /context with a parent class

    context 'with an optional parent' do
      resource(:poise_test) do
        include described_class
        poise_subresource(Chef::Resource::RubyBlock, true)
      end

      it { is_expected.to include Poise::Helpers::Subresources::Child }
      its(:parent_type) { is_expected.to eq Chef::Resource::RubyBlock }
      its(:parent_optional) { is_expected.to be_truthy }
    end # /context with an optional parent
  end # /describe #poise_subresource

  describe '#poise_fused' do
    resource(:poise_test) do
      include described_class
      poise_fused
    end

    it { is_expected.to include Poise::Resource }
    it { is_expected.to include Poise::Helpers::Fused }
  end # /describe #poise_fused

  describe '#poise_inversion' do
    context 'with an options resource' do
      resource(:poise_test) do
        include described_class
        poise_inversion
        provides(:poise_test)
        Halite::SpecHelper::Patcher.post_create_cleanup(:poise_test_options, inversion_options_resource_class)
        Halite::SpecHelper::Patcher.post_create_cleanup(:poise_test_options, inversion_options_provider_class)
      end
      it { is_expected.to include Poise::Resource }
      it { is_expected.to include Poise::Helpers::Inversion }
      its(:inversion_options_resource_class) { is_expected.to be_truthy }
      its(:inversion_options_provider_class) { is_expected.to be_truthy }
    end # /context with an options resource

    context 'without an options resource' do
      resource(:poise_test) do
        include described_class
        poise_inversion(false)
        provides(:poise_test)
      end
      it { is_expected.to include Poise::Resource }
      it { is_expected.to include Poise::Helpers::Inversion }
      its(:inversion_options_resource_class) { is_expected.to be nil }
      its(:inversion_options_provider_class) { is_expected.to be nil }
      it { expect { Chef::Resource.resource_for_node(:poise_test_options, chef_run.node) }.to raise_error Chef::Exceptions::NoSuchResourceType }
    end # /context without an options resource
  end # /describe #poise_inversion
end
