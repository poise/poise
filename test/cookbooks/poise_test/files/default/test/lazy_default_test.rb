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

class LazyDefaultTest < MiniTest::Chef::TestCase
  def test_one_run
    r = run_context.resource_collection.find(lazy_default_test_one: 'a')
    assert r
    assert_nil r.eager_test
    assert_equal r.lazy_test, :b
  end

  def test_two_run
    r = run_context.resource_collection.find(lazy_default_test_two: 'b')
    assert r
    assert_nil r.eager_test
    assert_equal r.lazy_test, :d
  end

  def test_three_run
    r = run_context.resource_collection.find(lazy_default_test_three: 'c')
    assert r
    assert_nil r.eager_test
    assert_equal r.lazy_test, :f
  end
end
