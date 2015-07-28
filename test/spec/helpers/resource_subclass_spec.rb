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

# Not defined using the helpers because I need it to be visible outside of
# example execution.
module PoiseTestSubclass
  class Resource < Chef::Resource
    include Poise
    provides(:poise_test_subclass)
  end
  class Provider < Chef::Provider
    include Poise
    provides(:poise_test_subclass)
    def action_run
      node.run_state[:really_did_run] = true
    end
  end
end

describe Poise::Helpers::ResourceSubclass do
  resource(:poise_sub, parent: PoiseTestSubclass::Resource) do
    provides(:poise_sub)
    subclass_providers!
  end
  recipe do
    poise_sub 'test'
  end

  it { is_expected.to run_poise_sub('test') }
  it { expect(chef_run.node.run_state[:really_did_run]).to be true }
end
