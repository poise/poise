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

class Chef
  # Using the Poise::Resource::LazyDefault module
  class Resource::LazyDefaultTestOne < Resource
    include Poise::Resource::LWRPPolyfill
    include Poise::Resource::LazyDefault

    def initialize(*args)
      super
      @resource_name = :lazy_default_test_one
      @action = :nothing
    end

    class << self
      attr_accessor :global_variable
    end

    attribute(:eager_test, default: LazyDefaultTestOne.global_variable)
    attribute(:lazy_test, default: lazy { LazyDefaultTestOne.global_variable })
  end

  class Provider::LazyDefaultTestOne < Provider
    def load_current_resource
    end
  end

  # Using the Poise::Resource helper
  class Resource::LazyDefaultTestTwo < Resource
    include Poise::Resource

    def initialize(*args)
      super
      @resource_name = :lazy_default_test_two
      @action = :nothing
    end

    class << self
      attr_accessor :global_variable
    end

    attribute(:eager_test, default: LazyDefaultTestTwo.global_variable)
    attribute(:lazy_test, default: lazy { LazyDefaultTestTwo.global_variable })
  end

  class Provider::LazyDefaultTestTwo < Provider
    def load_current_resource
    end
  end

 # Using the Poise helper
  class Resource::LazyDefaultTestThree < Resource
    include Poise

    def initialize(*args)
      super
      @resource_name = :lazy_default_test_three
      @action = :nothing
    end

    class << self
      attr_accessor :global_variable
    end

    attribute(:eager_test, default: LazyDefaultTestThree.global_variable)
    attribute(:lazy_test, default: lazy { LazyDefaultTestThree.global_variable })
  end

  class Provider::LazyDefaultTestThree < Provider
    def load_current_resource
    end
  end
end
