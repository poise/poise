#
# Author:: Noah Kantrowitz <noah@coderanger.net>
#
# Copyright 2013, Balanced, Inc.
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

ruby_block 'include_recipe_b_1' do
  block do
    node.run_state[:include_recipe_b_1] ||= 0
    node.run_state[:include_recipe_b_1] += 1
  end
end

ruby_block 'include_recipe_b_2' do
  block do
    node.run_state[:include_recipe_b_2] ||= 0
    node.run_state[:include_recipe_b_2] += 1
  end
end
