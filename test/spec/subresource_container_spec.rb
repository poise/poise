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


describe Poise::Resource::SubResourceContainer do
  provider(:poise_test)
  resource(:inner)
  provider(:inner)

  context 'with a single subresource' do
    resource(:poise_test) do
      include Poise::Resource::SubResourceContainer
    end
    recipe do
      poise_test 'container' do
        inner 'inner'
      end
    end

    it { is_expected.to run_poise_test('container') }
    it { is_expected.to run_inner('container::inner') }
  end # /context with a single subresource

  context 'with a multiple subresources' do
    resource(:poise_test) do
      include Poise::Resource::SubResourceContainer
    end
    recipe do
      poise_test 'container' do
        inner 'inner'
        inner 'inner2'
        inner 'inner3'
      end
    end

    it { is_expected.to run_poise_test('container') }
    it { is_expected.to run_inner('container::inner') }
    it { is_expected.to run_inner('container::inner2') }
    it { is_expected.to run_inner('container::inner3') }
  end # /context with a multiple subresources

  context 'with an explicit namespace' do
    resource(:poise_test) do
      include Poise::Resource::SubResourceContainer
      container_namespace('name')
    end
    recipe do
      poise_test 'container' do
        inner 'inner'
      end
    end

    it { is_expected.to run_poise_test('container') }
    it { is_expected.to run_inner('name::inner') }
  end # /context with an explicit namespace

  context 'with a no namespace' do
    resource(:poise_test) do
      include Poise::Resource::SubResourceContainer
      container_namespace(false)
    end
    recipe do
      poise_test 'container' do
        inner 'inner'
      end
    end

    it { is_expected.to run_poise_test('container') }
    it { is_expected.to run_inner('inner') }
  end # /context with a no namespace

  context 'with an explicit Proc namespace' do
    resource(:poise_test) do
      include Poise::Resource::SubResourceContainer
      container_namespace(Proc.new { name + '_name' })
    end
    recipe do
      poise_test 'container' do
        inner 'inner'
      end
    end

    it { is_expected.to run_poise_test('container') }
    it { is_expected.to run_inner('container_name::inner') }
  end # /context with an explicit Proc namespace
end
