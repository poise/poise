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
require 'chef/resource'
require 'chef/provider'


module ResourceProviderMixinTest
  module Test
    include Poise::Utils::ResourceProviderMixin

    module Resource
    end

    module Provider
    end
  end

  class Resource < Chef::Resource
    include Test
  end

  class Provider < Chef::Provider
    include Test
  end

  module Test2
    include Poise::Utils::ResourceProviderMixin

    module Resource
      include Test
    end

    module Provider
      include Test
    end
  end

  class Resource2 < Chef::Resource
    include Test
    include Test2
  end

  class Provider2 < Chef::Provider
    include Test
    include Test2
  end
end

describe Poise::Utils::ResourceProviderMixin do
  context 'in a resource' do
    subject { ResourceProviderMixinTest::Resource }
    it { is_expected.to be < ResourceProviderMixinTest::Test::Resource }
  end

  context 'in a provider' do
    subject { ResourceProviderMixinTest::Provider }
    it { is_expected.to be < ResourceProviderMixinTest::Test::Provider }
  end

  context 'with nested usage' do
    context 'in a resource' do
      subject { ResourceProviderMixinTest::Resource2 }
      it { is_expected.to be < ResourceProviderMixinTest::Test::Resource }
      it { is_expected.to be < ResourceProviderMixinTest::Test2::Resource }
    end

    context 'in a provider' do
      subject { ResourceProviderMixinTest::Provider2 }
      it { is_expected.to be < ResourceProviderMixinTest::Test::Provider }
      it { is_expected.to be < ResourceProviderMixinTest::Test2::Provider }
    end
  end # /context with nested usage
end
