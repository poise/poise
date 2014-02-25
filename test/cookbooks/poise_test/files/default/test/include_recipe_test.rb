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

class IncludeRecipeTest < MiniTest::Chef::TestCase
  # Inner resources should be run and should viaible in global resource collection
  def test_one_run
    assert run_context.resource_collection.find(ruby_block: 'include_recipe_a').updated?
  end

  # Inner resources should be run exactly once
  def test_one_run_once
    assert_equal node.run_state[:include_recipe_a], 1
  end

  def test_two_run
    assert run_context.resource_collection.find(ruby_block: 'include_recipe_b_1').updated?
    assert run_context.resource_collection.find(ruby_block: 'include_recipe_b_2').updated?
  end

  def test_two_run_once
    assert_equal node.run_state[:include_recipe_b_1], 1
    assert_equal node.run_state[:include_recipe_b_2], 1
  end

  def test_three_run
    assert run_context.resource_collection.find(ruby_block: 'include_recipe_c').updated?
  end

  def test_three_one_compile_time
    assert run_context.resource_collection.find(ruby_block: 'include_recipe_d').updated?
  end
end
