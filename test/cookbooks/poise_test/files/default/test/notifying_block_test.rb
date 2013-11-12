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

class NotifyingBlockTest < MiniTest::Chef::TestCase
  def test_one_a_updated
    assert run_context.resource_collection.find(notifying_block_test_one: 'a').updated?
  end

  def test_one_b_not_updated
    assert !run_context.resource_collection.find(notifying_block_test_one: 'b').updated?
  end

  def test_one_a_run
    assert node.run_state[:notifying_block_test_inner] && node.run_state[:notifying_block_test_inner].include?('a')
  end

  def test_one_b_not_run
    refute node.run_state[:notifying_block_test_inner] && node.run_state[:notifying_block_test_inner].include?('b')
  end

  def test_two_a_updated
    assert run_context.resource_collection.find(notifying_block_test_two: 'a').updated?
  end

  def test_two_b_updated
    assert run_context.resource_collection.find(notifying_block_test_two: 'b').updated?
  end

  def test_two_c_updated
    assert run_context.resource_collection.find(notifying_block_test_two: 'c').updated?
  end

  def test_two_d_not_updated
    assert !run_context.resource_collection.find(notifying_block_test_two: 'd').updated?
  end

  def test_two_a_run
    assert node.run_state[:notifying_block_test_inner_one] && node.run_state[:notifying_block_test_inner_one].include?('a')
    assert node.run_state[:notifying_block_test_inner_two] && node.run_state[:notifying_block_test_inner_two].include?('a')
  end

  def test_two_b_run
    refute node.run_state[:notifying_block_test_inner_one] && node.run_state[:notifying_block_test_inner_one].include?('b')
    assert node.run_state[:notifying_block_test_inner_two] && node.run_state[:notifying_block_test_inner_two].include?('b')
  end

  def test_two_c_run
    assert node.run_state[:notifying_block_test_inner_one] && node.run_state[:notifying_block_test_inner_one].include?('c')
    refute node.run_state[:notifying_block_test_inner_two] && node.run_state[:notifying_block_test_inner_two].include?('c')
  end

  def test_two_d_not_run
    refute node.run_state[:notifying_block_test_inner_one] && node.run_state[:notifying_block_test_inner_one].include?('d')
    refute node.run_state[:notifying_block_test_inner_two] && node.run_state[:notifying_block_test_inner_two].include?('d')
  end

end
