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

describe Poise::Subcontext::ResourceCollection do
  include Poise::Helpers::SubcontextBlock
  let(:top_run_context) { Chef::RunContext.new(Chef::Node.new, nil, nil) }
  let(:top) { top_run_context.resource_collection }
  let(:sub_run_context) { subcontext_block(top_run_context) }
  let(:sub) { sub_run_context.resource_collection }
  let(:inner) { subcontext_block(sub_run_context).resource_collection }
  let(:sibling) { subcontext_block(top_run_context).resource_collection }
  subject(:subject_context) { sub }

  # Helper for use in #before.
  def res(name)
    Chef::Resource::RubyBlock.new(name, nil)
  end

  # Populate the various collections with test data.
  before do
    top << res('top1')
    top << res('top2')
    sub << res('sub1')
    sub << res('sub2')
    inner << res('inner1')
    inner << res('inner2')
    sibling << res('sibling1')
    sibling << res('sibling2')
  end

  describe '#lookup' do
    let(:name) { '' }
    subject { subject_context.lookup("ruby_block[#{name}]") }

    context 'with a resource in the subcontext' do
      let(:name) { 'sub1' }
      it { is_expected.to be_a Chef::Resource }
    end # /context with a resource in the subcontext

    context 'with a resource in a parent context' do
      let(:name) { 'top1' }
      it { is_expected.to be_a Chef::Resource }
    end # /context with a resource in a parent context

    context 'with a resource in a sibling context' do
      let(:name) { 'sibling1' }
      it { expect { subject }.to raise_error Chef::Exceptions::ResourceNotFound }
    end # /context with a resource in a sibling context

    context 'with a resource in a nested context' do
      let(:name) { 'inner1' }
      it { expect { subject }.to raise_error Chef::Exceptions::ResourceNotFound }
    end # /context with a resource in a nested context
  end # /describe #lookup

  describe '#recursive_each' do
    subject do
      [].tap do |ary|
        subject_context.recursive_each do |res|
          ary << res.name
        end
      end
    end
    it { is_expected.to eq %w{top1 top2 sub1 sub2} }

    context 'from a deeply nested context' do
      let(:subject_context) { inner }
      it { is_expected.to eq %w{top1 top2 sub1 sub2 inner1 inner2} }
    end # /context from a deeply nested context
  end # /describe #recursive_each

  describe '#reverse_recursive_each' do
    subject do
      [].tap do |ary|
        subject_context.reverse_recursive_each do |res|
          ary << res.name
        end
      end
    end
    it { is_expected.to eq %w{sub2 sub1 top2 top1} }

    context 'from a deeply nested context' do
      let(:subject_context) { inner }
      it { is_expected.to eq %w{inner2 inner1 sub2 sub1 top2 top1} }
    end # /context from a deeply nested context
  end # /describe #reverse_recursive_each
end
