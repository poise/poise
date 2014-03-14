#
# Author:: Noah Kantrowitz <noah@coderanger.net>
#
# Copyright 2013-2014, Noah Kantrowitz
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

include_recipe_test_one 'a' do
  included_recipe 'poise_test::include_recipe_a'
end

include_recipe_test_two 'b' do
  included_recipe 'poise_test::include_recipe_b'
end

include_recipe_test_three 'c' do
  included_recipe 'poise_test::include_recipe_c'
end

include_recipe_test_one 'd' do
  included_recipe 'poise_test::include_recipe_d'
  action :nothing
end.run_action(:run)
