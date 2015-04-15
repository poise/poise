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

describe Poise::Helpers::TemplateContent do
  resource(:poise_test) do
    include described_class
    attribute('', template: true)
  end
  provider(:poise_test)
  recipe do
    poise_test 'test'
  end

  # Stub out template rendering
  let(:required_template_options) { Hash.new }
  before do
    @fake_finder = double('fake TemplateFinder')
    allow(Chef::Provider::TemplateFinder).to receive(:new).and_return(@fake_finder)
    allow(@fake_finder).to receive(:find)
    @fake_ctx = double('fake TemplateContext')
    if required_template_options.empty?
      allow(Chef::Mixin::Template::TemplateContext).to receive(:new).and_return(@fake_ctx)
    else
      expect(Chef::Mixin::Template::TemplateContext).to receive(:new).with(hash_including(required_template_options)).and_return(@fake_ctx)
    end
    allow(@fake_ctx).to receive(:[]=)
    allow(@fake_ctx).to receive(:render_template).and_return('rendered template')
    # Also fake the cookbook lookup since that won't work in our test setup
    allow(Poise::Utils).to receive(:find_cookbook_name).and_return('poise')
  end

  context 'with no input' do
    recipe do
      poise_test 'test'
    end

    it { is_expected.to run_poise_test('test').with(content: nil) }
  end

  context 'with a simple template' do
    recipe do
      poise_test 'test' do
        source 'test.erb'
      end
    end

    it { is_expected.to run_poise_test('test').with(source: 'test.erb', content: 'rendered template') }

    it 'only runs the template render once' do
      expect(@fake_ctx).to receive(:render_template).and_return('rendered template').once
      subject.find_resource('poise_test', 'test').content
      subject.find_resource('poise_test', 'test').content
    end
  end # /context with a template

  context 'with some template variables' do
    recipe do
      poise_test 'test' do
        source 'test.erb'
        options do
          one '1'
          two 2
        end
      end
    end
    let(:required_template_options) { {'one' => '1', 'two' => 2} }

    it { is_expected.to run_poise_test('test').with(source: 'test.erb', options: required_template_options, content: 'rendered template') }
  end # /context with some template variables

  context 'with explicit content' do
    recipe do
      poise_test 'test' do
        content 'something explicit'
      end
    end

    it { is_expected.to run_poise_test('test').with(content: 'something explicit') }
  end # /context with explicit content

  context 'with a default template' do
    resource(:poise_test) do
      include described_class
      attribute('', template: true, default_source: 'test.erb')
    end

    it { is_expected.to run_poise_test('test').with(content: 'rendered template') }
  end # /context with a default template

  context 'with default content' do
    resource(:poise_test) do
      include described_class
      attribute('', template: true, default: 'default content')
    end

    it { is_expected.to run_poise_test('test').with(content: 'default content') }
  end # /context with default content

  context 'with a name prefix' do
    resource(:poise_test) do
      include described_class
      attribute(:config, template: true)
    end
    recipe do
      poise_test 'test' do
        config_source 'test.erb'
      end
    end

    it { is_expected.to run_poise_test('test').with(config_content: 'rendered template') }
  end # /context with a name prefix

  context 'with required content' do
    resource(:poise_test) do
      include described_class
      attribute(:config, template: true, required: true)
    end

    it { expect{chef_run}.to raise_error(Chef::Exceptions::ValidationFailed) }
  end # /context with required content

  context 'with both source and content' do
    recipe do
      poise_test 'test' do
        source 'test.erb'
        content 'content'
      end
    end

    it { expect{chef_run}.to raise_error(Chef::Exceptions::ValidationFailed) }
  end # /context with both source and content
end
