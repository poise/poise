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

class TemplateContentTest < MiniTest::Chef::TestCase
  def test_one_a
    assert_equal run_context.resource_collection.find(template_content_test_one: 'a').content, 'I am a teapot.'
  end

  def test_one_b
    assert_equal run_context.resource_collection.find(template_content_test_one: 'b').content, "Short and stout.\n"
  end

  def test_one_c
    assert_equal run_context.resource_collection.find(template_content_test_one: 'c').content, "Here is my handle.\n"
  end

  def test_one_d
    assert_equal run_context.resource_collection.find(template_content_test_one: 'd').content, "Here is my spout.\n"
  end

  def test_one_e
    assert_equal run_context.resource_collection.find(template_content_test_one: 'e').content, "When I get all steamed up.\n"
  end

  def test_one_f
    assert_equal run_context.resource_collection.find(template_content_test_one: 'f').content, nil
  end

  def test_one_invalid
    res = Chef::Resource::TemplateContentTestOne.new('invalid', run_context)
    res.source('foo')
    res.content('bar')
    assert_raises(Chef::Exceptions::ValidationFailed) { res.after_created }
  end


  def test_two_a
    assert_equal run_context.resource_collection.find(template_content_test_two: 'a').thing_content, 'I am a teapot.'
  end

  def test_two_b
    assert_equal run_context.resource_collection.find(template_content_test_two: 'b').thing_content, "Short and stout.\n"
  end

  def test_two_c
    assert_equal run_context.resource_collection.find(template_content_test_two: 'c').thing_content, "Here is my handle.\n"
  end

  def test_two_d
    assert_equal run_context.resource_collection.find(template_content_test_two: 'd').thing_content, "Here is my spout.\n"
  end

  def test_two_e
    assert_equal run_context.resource_collection.find(template_content_test_two: 'e').thing_content, "When I get all steamed up.\n"
  end


  def test_three_a
    assert_equal run_context.resource_collection.find(template_content_test_three: 'a').content, 'I am a teapot.'
  end

  def test_three_b
    assert_equal run_context.resource_collection.find(template_content_test_three: 'b').content, "Short and stout.\n"
  end

  def test_three_c
    assert_equal run_context.resource_collection.find(template_content_test_three: 'c').content, 'Hello world'
  end


  def test_four_invalid
    res = Chef::Resource::TemplateContentTestFour.new('invalid', run_context)
    assert_raises(Chef::Exceptions::ValidationFailed) { res.after_created }
    #assert_raises(Chef::Exceptions::ValidationFailed) { res.content }
  end

  def test_four_a
    assert_equal run_context.resource_collection.find(template_content_test_four: 'a').content, "I will shout."
  end


  def test_five
    res = Chef::Resource::TemplateContentTestFive.new('five', run_context)
    assert !res.after_created_called
    res.after_created
    assert res.after_created_called
  end


  def test_six_a
    assert_equal run_context.resource_collection.find(template_content_test_six: 'a').content, "Tip me over.\n"
  end

  def test_six_inner_a
    assert_equal run_context.resource_collection.find(template_content_test_six_inner: 'a').content, "Tip you over.\n"
  end


  def test_seven_outer_a
    assert_equal run_context.resource_collection.find(template_content_test_seven_outer: 'a').content, "And pour you out.\n"
  end

  def test_seven_a
    assert_equal run_context.resource_collection.find(template_content_test_seven: 'a').content, "And pour me out.\n"
  end

end
