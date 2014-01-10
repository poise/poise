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

class Chef
  class Provider::TemplateContentTest < Provider
    def load_current_resource
    end

    def action_run
    end
  end

  # Simple test with no prefix
  class Resource::TemplateContentTestOne < Resource
    include Poise::Resource::TemplateContent

    def initialize(*args)
      super
      @resource_name = :template_content_test_one
      @action = :run
    end

    attribute('', template: true)
  end

  class Provider::TemplateContentTestOne < Provider::TemplateContentTest; end

  # Test with a prefix
  class Resource::TemplateContentTestTwo < Resource
    include Poise::Resource::TemplateContent

    def initialize(*args)
      super
      @resource_name = :template_content_test_two
      @action = :run
    end

    attribute(:thing, template: true)
  end

  class Provider::TemplateContentTestTwo < Provider::TemplateContentTest; end

  # Test with default content
  class Resource::TemplateContentTestThree < Resource
    include Poise::Resource::TemplateContent

    def initialize(*args)
      super
      @resource_name = :template_content_test_three
      @action = :run
    end

    attribute('', template: true, default: 'Hello world')
  end

  class Provider::TemplateContentTestThree < Provider::TemplateContentTest; end

  # Test with required content
  class Resource::TemplateContentTestFour < Resource
    include Poise::Resource::TemplateContent

    def initialize(*args)
      super
      @resource_name = :template_content_test_four
      @action = :run
    end

    attribute('', template: true, required: true)
  end

  class Provider::TemplateContentTestFour < Provider::TemplateContentTest; end

  # Used to check that after_created is being called up the chain correctly
  class Resource::TemplateContentTestFiveOuter < Resource
    attr_reader :after_created_called
    def after_created
      super
      @after_created_called = true
    end
  end

  class Resource::TemplateContentTestFive < Resource::TemplateContentTestFiveOuter
    include Poise::Resource::TemplateContent

    def initialize(*args)
      super
      @resource_name = :template_content_test_five
      @action = :run
    end

    attribute('', template: true)
  end

  class Provider::TemplateContentTestFive < Provider::TemplateContentTest; end

  # Six is located in poise_test2

  # Test for options inheritance behavior
  class Resource::TemplateContentTestSevenOuter < Resource
    include Poise::Resource::TemplateContent

    def initialize(*args)
      super
      @resource_name = :template_content_test_seven_outer
      @action = :run
    end

    attribute('', template: true, default_source: 'seven_outer.erb', default_options: {direction: 'out'})
  end

  class Provider::TemplateContentTestSevenOuter < Provider::TemplateContentTest; end

  class Resource::TemplateContentTestSeven < Resource::TemplateContentTestSevenOuter
    def initialize(*args)
      super
      @resource_name = :template_content_test_seven
    end

    attribute('', template: true, default_source: 'seven.erb')
  end

  class Provider::TemplateContentTestSeven < Provider::TemplateContentTest; end

end
