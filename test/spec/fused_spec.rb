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
require 'poise/fused'

describe Poise::Resource::Fused do
  resource(:poise_test) do
    include Poise::Resource::Fused

    action(:run) do
      ruby_block 'inner'
    end
  end
  recipe do
    poise_test 'test'
  end

  it { is_expected.to run_ruby_block('inner') }

  context 'with a nested provider' do
    resource(:poise_test) do
      include Poise::Resource::Fused

      action(:run) do
        file 'inner' do
          content new_resource.name
        end
      end
    end

    it { is_expected.to create_file('inner').with(content: 'test') }
  end # /context with a nested provider
end
