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

describe file('/inversion/a') do
  it { is_expected.to be_a_file }
end

describe file('/inversion/b') do
  it { is_expected.to be_a_file }
  # Pending https://github.com/chef/train/issues/81.
  its(:content) { is_expected.to match /^one\s*$/ }
end

describe file('/inversion/c') do
  it { is_expected.to be_a_file }
  # Pending https://github.com/chef/train/issues/81.
  its(:content) { is_expected.to match /^two\s*$/ }
end

describe file('/inversion/d') do
  it { is_expected.to be_a_file }
  # Pending https://github.com/chef/train/issues/81.
  its(:content) { is_expected.to match /^d-three\s*$/ }
end

describe file('/inversion/e') do
  it { is_expected.to be_a_file }
  # Pending https://github.com/chef/train/issues/81.
  its(:content) { is_expected.to match /^e-three\s*$/ }
end

