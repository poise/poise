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

template_content_test_one 'a' do
  content 'I am a teapot.'
end

template_content_test_one 'b' do
  source 'template_content_test_b.erb'
end

template_content_test_one 'c' do
  source 'template_content_test_c.erb'
  cookbook 'poise_test'
end

template_content_test_one 'd' do
  source 'template_content_test_d.erb'
  cookbook 'poise_test2'
end

template_content_test_one 'e' do
  source 'template_content_test_e.erb'
  options do
    status 'steamed'
  end
end

template_content_test_one 'f'


template_content_test_two 'a' do
  thing_content 'I am a teapot.'
end

template_content_test_two 'b' do
  thing_source 'template_content_test_b.erb'
end

template_content_test_two 'c' do
  thing_source 'template_content_test_c.erb'
  thing_cookbook 'poise_test'
end

template_content_test_two 'd' do
  thing_source 'template_content_test_d.erb'
  thing_cookbook 'poise_test2'
end

template_content_test_two 'e' do
  thing_source 'template_content_test_e.erb'
  thing_options do
    status 'steamed'
  end
end


template_content_test_three 'a' do
  content 'I am a teapot.'
end

template_content_test_three 'b' do
  source 'template_content_test_b.erb'
end

template_content_test_three 'c'


template_content_test_four 'a' do
  content 'I will shout.'
end


template_content_test_six 'a'

template_content_test_six_inner 'a'


template_content_test_seven_outer 'a'

template_content_test_seven 'a'
