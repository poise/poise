#
# Copyright 2015-2016, Noah Kantrowitz
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

# Disable this test if Chef::Resource::File::Verification doesn't exist because
# it doesn't matter anyway.
describe Poise::Backports::VERIFY_PATH, if: defined?(Chef::Resource::File::Verification) do
  it do
    verifier = Chef::Resource::File::Verification.new(nil, "mycmd #{subject}", nil)
    expect(Chef::GuardInterpreter).to receive(:for_resource).with(nil, 'mycmd /path', nil).and_return(double(evaluate: nil))
    verifier.verify_command('/path', nil)
  end
end
