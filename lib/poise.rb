#
# Copyright 2013-2015, Noah Kantrowitz
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

require 'poise/chefspec_matchers'
require 'poise/defined_in'
require 'poise/fused'
require 'poise/include_recipe'
require 'poise/lazy_default'
require 'poise/lwrp_polyfill'
require 'poise/notifying_block'
require 'poise/option_collector'
require 'poise/resource_name'
require 'poise/subresources'
require 'poise/template_content'

module Poise
  module Resource
    include ChefspecMatchers
    include DefinedIn
    include LazyDefault
    include LWRPPolyfill
    include OptionCollector
    include ResourceName
    include TemplateContent

    # @!classmethods
    module ClassMethods
      def poise_subresource_container(namespace=nil)
        include Poise::Resource::SubResourceContainer
        container_namespace(namespace) unless namespace.nil?
      end

      def poise_subresource(parent_type=nil, parent_optional=nil)
        include Poise::Resource::SubResource
        parent_type(parent_type) if parent_type
        parent_optional(parent_optional) if parent_optional
      end

      def poise_fused
        include Poise::Resource::Fused
      end

      def included(klass)
        super
        klass.extend ClassMethods
      end
    end

    extend ClassMethods
  end

  module Provider
    include DefinedIn
    include IncludeRecipe
    include LWRPPolyfill
    include NotifyingBlock
  end

  # Include in the correct module for the class type.
  #
  # @api private
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
def Poise(options={})
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
      klass.poise_subresource_container(options[:container_namespace]) if options[:container]
      klass.poise_fused if options[:fused]
    end
    # Add Provider-specific options here when needed
  end

  mod
end
