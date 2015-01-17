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

describe Poise::Resource::LWRPPolyfill do
  resource(:poise_test) do
    include Poise::Resource::LWRPPolyfill
    attribute(:boolean, equal_to: [true, false])
  end

  provider(:poise_test)

  context 'with default value' do
    recipe do
      poise_test 'nil'
    end

    it { is_expected.to run_poise_test('nil').with(boolean: nil) }
  end

  context 'with true value' do
    recipe do
      poise_test 'true' do
        boolean true
      end
    end

    it { is_expected.to run_poise_test('true').with(boolean: true) }
  end

  context 'with false value' do
    recipe do
      poise_test 'false' do
        boolean false
      end
    end

    it { is_expected.to run_poise_test('false').with(boolean: false) }
  end

  context 'with string value' do
    recipe do
      poise_test 'true' do
        boolean 'boom'
      end
    end

    it { expect { subject }.to raise_error Chef::Exceptions::ValidationFailed }
  end

end
