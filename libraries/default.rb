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
require File.expand_path('../lazy_default', __FILE__)
require File.expand_path('../lwrp_polyfill', __FILE__)
require File.expand_path('../notifying_block', __FILE__)
require File.expand_path('../option_collector', __FILE__)
require File.expand_path('../resource_name', __FILE__)
require File.expand_path('../template_content', __FILE__)

module Poise
  module Resource
    include LazyDefault
    include LWRPPolyfill
    include OptionCollector
    include ResourceName
    include TemplateContent

    def self.included(klass)
      super
      def klass.poise_subresource_container
        include Poise::Resource::SubResourceContainer
      end

      def klass.poise_subresource(parent_type=nil, parent_optional=nil)
        include Poise::Resource::SubResource
        parent_type(parent_type) if parent_type
        parent_optional(parent_optional) if parent_optional
      end
    end
  end

  module Provider
    include IncludeRecipe
    include LWRPPolyfill
    include NotifyingBlock
  end

  def self.included(klass)
    super
    if klass < Chef::Resource
      klass.class_exec { include Poise::Resource }
    elsif klass < Chef::Provider
      klass.class_exec { include Poise::Provider }
    end
  end
end

# Callable form to allow passing in options:
#   include Poise(ParentResource)
#   include Poise(parent: ParentResource)
#   include Poise(container: true)
def Poise(options=nil)
  # Allow passing a class as a shortcut
  if options.is_a?(Class)
    options = {parent: options}
  end

  # Create a new anonymous module
  mod = Module.new

  # Fake the name
  def mod.name
    super || 'Poise'
  end

  mod.define_singleton_method(:included) do |klass|
    super(klass)
    # Pull in the main helper to cover most of the needed logic
    klass.class_exec { include Poise }
    # Resource-specific options
    if klass < Chef::Resource
      klass.poise_subresource(options[:parent], options[:parent_optional]) if options[:parent]
      klass.poise_subresource_container if options[:container]
    end
    # Add Provider-specific options here when needed
  end

  mod
end
