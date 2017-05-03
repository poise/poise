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
require 'chef/resource'
require 'chef/provider'

# Not defined using the helpers because I need it to be visible outside of
# example execution.
module PoiseTestSubclass
  class Resource < Chef::Resource
    include Poise
    provides(:poise_test_subclass)
    actions(:run)
  end
  class Provider < Chef::Provider
    include Poise
    provides(:poise_test_subclass)
    def action_run
      (node.run_state[:really_did_run] ||= []) << new_resource.name
    end
  end
  class Sub < Resource
    provides(:poise_test_subclass_sub)
    subclass_providers!
  end
end

describe Poise::Helpers::ResourceSubclass do
  describe '.subclass_providers!' do
    resource(:poise_sub, parent: PoiseTestSubclass::Resource) do
      provides(:poise_sub)
      subclass_providers!
    end
    recipe do
      poise_sub 'test'
    end

    it { is_expected.to run_poise_sub('test') }
    it { expect(chef_run.node.run_state[:really_did_run]).to eq %w{test} }

    context 'with multiple resource names' do
      before { step_into << :poise_test_subclass_other_name }
      resource(:poise_sub, parent: PoiseTestSubclass::Resource) do
        provides(:poise_sub)
        provides(:poise_test_subclass_other_name)
        subclass_providers!
      end
      recipe do
        poise_sub 'test'
        poise_test_subclass_other_name 'test2'
      end

      it { is_expected.to run_poise_sub('test') }
      it { is_expected.to ChefSpec::Matchers::ResourceMatcher.new('poise_test_subclass_other_name', 'run', 'test2') }
      it { expect(chef_run.node.run_state[:really_did_run]).to eq %w{test test2} }
    end # /context with multiple resource names

    context 'with a non-DSL subclass' do
      before { step_into << :poise_test_subclass_sub }
      recipe do
        poise_test_subclass_sub 'test'
      end

      it { is_expected.to run_poise_test_subclass_sub('test') }
      it { expect(chef_run.node.run_state[:really_did_run]).to eq %w{test} }
    end # /context with a non-DSL subclass
  end # /describe .subclass_providers!

  describe '.subclass_resource_equivalents' do
    let(:test_class) { nil }
    subject { test_class.subclass_resource_equivalents }
    resource(:poise_sub, parent: PoiseTestSubclass::Resource) do
      provides(:poise_sub)
      subclass_providers!
    end

    context 'with a top-level class' do
      let(:test_class) { PoiseTestSubclass::Resource }
      it { is_expected.to eq %i{poise_test_subclass} }
    end # /context with a top-level class

    context 'with a subclass' do
      let(:test_class) { resource(:poise_sub) }
      it { is_expected.to eq %i{poise_sub poise_test_subclass} }
    end # /context with a subclass

    context 'with a non-DSL subclass' do
      let(:test_class) { PoiseTestSubclass::Sub }
      it { is_expected.to eq %i{poise_test_subclass_sub poise_test_subclass} }
    end # /context with a non-DSL subclass

    context 'with an unpatched subclass' do
      resource(:poise_sub2, parent: PoiseTestSubclass::Resource) do
        provides(:poise_sub2)
      end
      let(:test_class) { resource(:poise_sub2) }
      it { is_expected.to eq %i{poise_sub2} }
    end # /context with an unpatched subclass

    context 'with two subclasses' do
      resource(:poise_sub2, parent: :poise_sub) do
        provides(:poise_sub2)
        subclass_providers!
      end
      let(:test_class) { resource(:poise_sub2) }
      it { is_expected.to eq %i{poise_sub2 poise_sub poise_test_subclass} }
    end # /context with two subclasses

    context 'with a non-poise parent' do
      resource(:non_poise_parent)
      resource(:poise_sub3, parent: :non_poise_parent) do
        include Poise
        provides(:poise_sub3)
        subclass_providers!
      end
      let(:test_class) { resource(:poise_sub3) }
      it { is_expected.to eq %i{poise_sub3 non_poise_parent} }
    end # /context with a non-poise parent
  end # /describe .subclass_resource_equivalents
end
