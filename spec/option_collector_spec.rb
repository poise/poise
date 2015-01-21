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

describe Poise::Resource::OptionCollector do
  resource(:poise_test) do
    include Poise::Resource::OptionCollector
    attribute(:options, option_collector: true)
  end
  provider(:poise_test)

  context 'with a block' do
    recipe do
      poise_test 'test' do
        options do
          one '1'
          two 2
        end
      end
    end

    it { is_expected.to run_poise_test('test').with(options: {one: '1', two: 2}) }
  end

  context 'with a hash' do
    recipe do
      poise_test 'test' do
        options one: '1', two: 2
      end
    end

    it { is_expected.to run_poise_test('test').with(options: {one: '1', two: 2}) }
  end

  context 'with both a block and a hash' do
    recipe do
      poise_test 'test' do
        options one: '1', two: 2 do
          two 3
          three 'three'
        end
      end
    end

    it { is_expected.to run_poise_test('test').with(options: {one: '1', two: 3, three: 'three'}) }
  end
end
