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

require File.expand_path('../include_recipe', __FILE__)
require File.expand_path('../notifying_block', __FILE__)
require File.expand_path('../lazy_default', __FILE__)
require File.expand_path('../option_collector', __FILE__)

module Poise
  module Resource
    include LazyDefault
    include OptionCollector

    def self.included(klass)
      super
      def klass.poise_subresource_container
        include Poise::Resource::SubResourceContainer
      end

      def klass.poise_subresource(parent_type=nil)
        include Poise::Resource::SubResource
        parent_type(parent_type) if parent_type
      end
    end
  end

  module Provider
    include IncludeRecipe
    include NotifyingBlock
  end

  def self.included(klass)
    if klass < Chef::Resource
      klass.class_exec { include Poise::Resource }
    elsif klass < Chef::Provider
      klass.class_exec { include Poise::Provider }
    end
  end
end
