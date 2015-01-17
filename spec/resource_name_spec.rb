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

describe Poise::Resource::ResourceName do
  resource(:poise_test) do
    include Poise::Resource::ResourceName

    # Undo the setting from the spec_helper
    def initialize(*args)
      @resource_name = nil
      super
    end
  end

  it 'sets the resource_name' do
    expect(Chef::Resource::PoiseTest.new(nil).resource_name).to eq :poise_test
  end
end
