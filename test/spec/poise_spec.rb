#
# Copyright 2013-2015, Noah Kantrowitz
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

describe Poise do
  context 'with a Resource' do
    resource(:poise_test) do
      include Poise
    end

    subject { Chef::Resource::PoiseTest }

    it { is_expected.to include(Poise::Resource) }
    it { is_expected.to include(Poise::Resource::LazyDefault) }
    it { is_expected.to include(Poise::Resource::LWRPPolyfill) }
    it { is_expected.to include(Poise::Resource::OptionCollector) }
    it { is_expected.to include(Poise::Resource::ResourceName) }
    it { is_expected.to include(Poise::Resource::TemplateContent) }
    it { is_expected.to include(Poise::ChefspecMatchers) }

    context 'as a function call' do
      context 'with no arguments' do
        resource(:poise_test) do
          include Poise()
        end

        it { is_expected.to include(Poise) }
        it { is_expected.to include(Poise::Resource) }
      end # /context with no arguments

      context 'with a parent class' do
        resource(:poise_test) do
          include Poise(parent: Chef::Resource::RubyBlock)
        end

        it { is_expected.to include(Poise) }
        it { is_expected.to include(Poise::Resource) }
        it { is_expected.to include(Poise::Resource::SubResource) }
        its(:parent_type) { is_expected.to eq Chef::Resource::RubyBlock }
        its(:parent_optional) { is_expected.to be_falsey }
      end # /context with a parent class

      context 'with a parent class shortcut' do
        resource(:poise_test) do
          include Poise(Chef::Resource::RubyBlock)
        end

        it { is_expected.to include(Poise) }
        it { is_expected.to include(Poise::Resource) }
        it { is_expected.to include(Poise::Resource::SubResource) }
        its(:parent_type) { is_expected.to eq Chef::Resource::RubyBlock }
        its(:parent_optional) { is_expected.to be_falsey }
      end # /context with a parent class shortcut

      context 'with an optional parent' do
        resource(:poise_test) do
          include Poise(parent: Chef::Resource::RubyBlock, parent_optional: true)
        end

        it { is_expected.to include(Poise) }
        it { is_expected.to include(Poise::Resource) }
        it { is_expected.to include(Poise::Resource::SubResource) }
        its(:parent_type) { is_expected.to eq Chef::Resource::RubyBlock }
        its(:parent_optional) { is_expected.to be_truthy }
      end # /context with an optional parent

      context 'with a container' do
        resource(:poise_test) do
          include Poise(container: true)
        end

        it { is_expected.to include(Poise) }
        it { is_expected.to include(Poise::Resource) }
        it { is_expected.to include(Poise::Resource::SubResourceContainer) }
      end # /context with a container

      context 'with both a parent and a container' do
        resource(:poise_test) do
          include Poise(parent: Chef::Resource::RubyBlock, container: true)
        end

        it { is_expected.to include(Poise) }
        it { is_expected.to include(Poise::Resource) }
        it { is_expected.to include(Poise::Resource::SubResource) }
        it { is_expected.to include(Poise::Resource::SubResourceContainer) }
        its(:parent_type) { is_expected.to eq Chef::Resource::RubyBlock }
        its(:parent_optional) { is_expected.to be_falsey }
      end # /context with both a parent and a container

      context 'with fused' do
        resource(:poise_test) do
          include Poise(fused: true)
        end

        it { is_expected.to include(Poise) }
        it { is_expected.to include(Poise::Resource) }
        it { is_expected.to include(Poise::Resource::Fused) }
      end # /context with fused
    end # /context as a function call
  end # /context for a Resource

  context 'with a Provider' do
    provider(:poise_test) do
      include Poise
    end

    subject { Chef::Provider::PoiseTest }

    it { is_expected.to include(Poise::Provider) }
    it { is_expected.to include(Poise::Provider::IncludeRecipe) }
    it { is_expected.to include(Poise::Provider::LWRPPolyfill) }
    it { is_expected.to include(Poise::Provider::NotifyingBlock) }

    context 'as a function call' do
      provider(:poise_test) do
        include Poise()
      end

      it { is_expected.to include(Poise) }
      it { is_expected.to include(Poise::Provider) }
    end # /context as a function call
  end # /context for a Provider

  it 'has a fake name when used a function' do
    expect(Poise().name).to eq 'Poise'
  end
end # /describe Poise

describe Poise::Resource do
  resource(:poise_test) do
    include Poise::Resource
  end

  subject { Chef::Resource::PoiseTest }

  it { is_expected.to include(Poise::Resource::LazyDefault) }
  it { is_expected.to include(Poise::Resource::LWRPPolyfill) }
  it { is_expected.to include(Poise::Resource::OptionCollector) }
  it { is_expected.to include(Poise::Resource::ResourceName) }
  it { is_expected.to include(Poise::Resource::TemplateContent) }
  it { is_expected.to include(Poise::ChefspecMatchers) }

  describe '#poise_subresource_container' do
    resource(:poise_test) do
      include Poise::Resource
      poise_subresource_container
    end

    it { is_expected.to include(Poise::Resource::SubResourceContainer) }
  end # /describe #poise_subresource_container

  describe '#poise_subresource' do
    context 'with no arguments' do
      resource(:poise_test) do
        include Poise::Resource
        poise_subresource
      end

      it { is_expected.to include(Poise::Resource::SubResource) }
      its(:parent_type) { is_expected.to eq Chef::Resource }
      its(:parent_optional) { is_expected.to be_falsey }
    end # /context with no arguments

    context 'with a parent class' do
      resource(:poise_test) do
        include Poise::Resource
        poise_subresource(Chef::Resource::RubyBlock)
      end

      it { is_expected.to include(Poise::Resource::SubResource) }
      its(:parent_type) { is_expected.to eq Chef::Resource::RubyBlock }
      its(:parent_optional) { is_expected.to be_falsey }
    end # /context with a parent class

    context 'with an optional parent' do
      resource(:poise_test) do
        include Poise::Resource
        poise_subresource(Chef::Resource::RubyBlock, true)
      end

      it { is_expected.to include(Poise::Resource::SubResource) }
      its(:parent_type) { is_expected.to eq Chef::Resource::RubyBlock }
      its(:parent_optional) { is_expected.to be_truthy }
    end # /context with an optional parent
  end # /describe #poise_subresource

  context 'with fused' do
    resource(:poise_test) do
      include Poise::Resource
      poise_fused
    end

    it { is_expected.to include(Poise::Resource) }
    it { is_expected.to include(Poise::Resource::Fused) }
  end # /context with fused
end # /describe Poise::Resource

describe Poise::Provider do
  provider(:poise_test) do
    include Poise
  end

  subject { Chef::Provider::PoiseTest }

  it { is_expected.to include(Poise::Provider::IncludeRecipe) }
  it { is_expected.to include(Poise::Provider::LWRPPolyfill) }
  it { is_expected.to include(Poise::Provider::NotifyingBlock) }
end # /describe Poise::Provider
