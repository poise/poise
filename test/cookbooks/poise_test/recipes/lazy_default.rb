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

Chef::Resource::LazyDefaultTestOne.global_variable = :a

lazy_default_test_one 'a'

Chef::Resource::LazyDefaultTestOne.global_variable = :b


Chef::Resource::LazyDefaultTestTwo.global_variable = :c

lazy_default_test_two 'b'

Chef::Resource::LazyDefaultTestTwo.global_variable = :d


Chef::Resource::LazyDefaultTestThree.global_variable = :e

lazy_default_test_three 'c'

Chef::Resource::LazyDefaultTestThree.global_variable = :f
