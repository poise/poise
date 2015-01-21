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

class LazyDefaultHelper < Chef::Resource
  include Poise::Resource::LWRPPolyfill
  include Poise::Resource::LazyDefault
end

describe Poise::Resource::LazyDefault do
  resource(:poise_test) do
    include Poise::Resource::LWRPPolyfill
    include Poise::Resource::LazyDefault
    attribute(:value, default: lazy { name + '_lazy' })
  end
  provider(:poise_test)
  recipe do
    poise_test 'test'
  end

  it { is_expected.to run_poise_test('test').with(value: 'test_lazy') }

  context 'in a subclass' do
    resource(:poise_test, parent: LazyDefaultHelper) do
      attribute(:value, default: lazy { name + '_lazy' })
    end

    it { is_expected.to run_poise_test('test').with(value: 'test_lazy') }
  end

  # TODO: Test that the value of the lazy eval isn't cached
end
