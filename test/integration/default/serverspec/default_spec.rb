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

require 'serverspec'
set :backend, :exec

describe file('/srv/app') do
  it { is_expected.to be_a_directory }
  it { is_expected.to be_owned_by 'root' }
end

describe file('/srv/app/defaults.conf') do
  it { is_expected.to be_a_file }
  it { is_expected.to be_owned_by 'root' }
  its(:content) { is_expected.to eq 'some defaults' }
end

describe file('/srv/app/user.conf') do
  it { is_expected.to be_a_file }
  it { is_expected.to be_owned_by 'root' }
  its(:content) { is_expected.to eq 'user config' }
end
