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

begin
  require 'chefspec'
  require 'rspec/expectations'
rescue LoadError
  # Don't panic! We will no-op later on if these aren't available.
end

require 'poise/lwrp_polyfill'
require 'poise/resource_name'

module Poise
  # Mixin to register ChefSpec matchers for a resource automatically.
  #
  # If you are using the provides() form for naming resources, ensure that is
  # set before declaring actions.
  #
  # @since 1.1.0
  # @example
  #   class Chef::Resource::MyResource < Chef::Resource
  #     include Poise::ChefspecMatchers
  #     actions(:run)
  #   end
  #   # ...
  #   expect(chef_run).to run_my_resource('...')
  module ChefspecMatchers
    include Resource::LWRPPolyfill
    include Resource::ResourceName

    # Create a matcher for a given resource type and action. This is
    # idempotent so if a matcher already exists, it will not be recreated.
    #
    # @!visibility private
    def self.create_matcher(resource, action)
      # Check that we have everything we need.
      return unless defined?(ChefSpec) && defined?(RSpec::Matchers) && resource
      method = :"#{action}_#{resource}"
      return if RSpec::Matchers.method_defined?(method)
      RSpec::Matchers.send(:define_method, method) do |resource_name|
        ChefSpec::Matchers::ResourceMatcher.new(resource, action, resource_name)
      end
    end

    # @!classmethods
    module ClassMethods
      # Create matchers for all declared actions.
      def actions(*names)
        super.tap do |actions|
          actions.each do |action|
            Poise::ChefspecMatchers.create_matcher(resource_name, action)
          end
        end
      end

      def included(klass)
        super
        klass.extend ClassMethods
      end
    end

    extend ClassMethods
  end
end
