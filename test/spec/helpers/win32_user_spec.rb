#
# Copyright 2016, Noah Kantrowitz
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

describe Poise::Helpers::Win32User do
  let(:chefspec_options) { {platform: 'ubuntu', version: '14.04'} }
  provider(:poise_test)
  before do
    allow(Poise::Utils::Win32).to receive(:admin_user).and_return('Administrator')
  end

  context 'user property' do
    resource(:poise_test) do
      include Poise::Helpers::LWRPPolyfill
      include described_class
      attribute(:user, default: 'root')
    end

    context 'with a default' do
      recipe do
        poise_test 'test'
      end

      context 'on Linux' do
        it { is_expected.to run_poise_test('test').with(user: 'root') }
      end # /context on Linux

      context 'on Windows' do
        let(:chefspec_options) { {platform: 'windows', version: '2012R2'} }
        it { is_expected.to run_poise_test('test').with(user: 'Administrator') }
      end # /context on Windows
    end # /context with a default

    context 'with a value' do
      recipe do
        poise_test 'test' do
          user 'other'
        end
      end

      context 'on Linux' do
        it { is_expected.to run_poise_test('test').with(user: 'other') }
      end # /context on Linux

      context 'on Windows' do
        let(:chefspec_options) { {platform: 'windows', version: '2012R2'} }
        it { is_expected.to run_poise_test('test').with(user: 'other') }
      end # /context on Windows
    end # /context with a value
  end # /context user property

  context 'owner property' do
    resource(:poise_test) do
      include Poise::Helpers::LWRPPolyfill
      include described_class
      attribute(:owner, default: 'root')
    end

    context 'with a default' do
      recipe do
        poise_test 'test'
      end

      context 'on Linux' do
        it { is_expected.to run_poise_test('test').with(owner: 'root') }
      end # /context on Linux

      context 'on Windows' do
        let(:chefspec_options) { {platform: 'windows', version: '2012R2'} }
        it { is_expected.to run_poise_test('test').with(owner: 'Administrator') }
      end # /context on Windows
    end # /context with a default

    context 'with a value' do
      recipe do
        poise_test 'test' do
          owner 'other'
        end
      end

      context 'on Linux' do
        it { is_expected.to run_poise_test('test').with(owner: 'other') }
      end # /context on Linux

      context 'on Windows' do
        let(:chefspec_options) { {platform: 'windows', version: '2012R2'} }
        it { is_expected.to run_poise_test('test').with(owner: 'other') }
      end # /context on Windows
    end # /context with a value
  end # /context owner property

  context 'group property' do
    resource(:poise_test) do
      include Poise::Helpers::LWRPPolyfill
      include described_class
      attribute(:group, default: 'root')
    end

    context 'with a default' do
      recipe do
        poise_test 'test'
      end

      context 'on Linux' do
        it { is_expected.to run_poise_test('test').with(group: 'root') }
      end # /context on Linux

      context 'on Windows' do
        let(:chefspec_options) { {platform: 'windows', version: '2012R2'} }
        # This test is written to be silly because Fauxhai doesn't have
        # root_group data for Windows.
        it { is_expected.to run_poise_test('test').with(group: chef_run.node['root_group']) }
      end # /context on Windows

      context 'on AIX' do
        let(:chefspec_options) { {platform: 'aix', version: '6.1'} }
        it { is_expected.to run_poise_test('test').with(group: 'system') }
      end # /context on AIX
    end # /context with a default

    context 'with a value' do
      recipe do
        poise_test 'test' do
          group 'other'
        end
      end

      context 'on Linux' do
        it { is_expected.to run_poise_test('test').with(group: 'other') }
      end # /context on Linux

      context 'on Windows' do
        let(:chefspec_options) { {platform: 'windows', version: '2012R2'} }
        it { is_expected.to run_poise_test('test').with(group: 'other') }
      end # /context on Windows
    end # /context with a value
  end # /context group property

  describe 'interaction with lazy defaults' do
    let(:chefspec_options) { {platform: 'windows', version: '2012R2'} }
    recipe do
      poise_test 'test'
    end

    context 'with a non-lazy default' do
      resource(:poise_test) do
        include Poise::Resource
        attribute(:user, default: 'root')
      end

      it { is_expected.to run_poise_test('test').with(user: 'Administrator') }
    end # /context with a non-lazy default

    context 'with a lazy default' do
      resource(:poise_test) do
        include Poise::Resource
        attribute(:user, default: lazy { 'root' })
      end

      it { is_expected.to run_poise_test('test').with(user: 'root') }
    end # /context with a lazy default
  end # /describe interaction with lazy defaults
end
