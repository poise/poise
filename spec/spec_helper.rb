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

require 'rspec'
require 'chefspec'
# require 'rspec/its'
require 'simplecov'
SimpleCov.start

require 'poise'

class HaliteRunner < ChefSpec::SoloRunner
  def self.converge(&block)
    new.tap do |instance|
      instance.converge(&block)
    end
  end

  def converge(&block)
    super do
      recipe = Chef::Recipe.new(nil, nil, run_context)
      recipe.instance_exec(&block)
    end
  end

  private

  # Don't try to autodetect
  def calling_cookbook_path(kaller)
    '/Users/coderanger/src/poise/empty'
  end
end

module Poise
  module SpecHelpers
    extend RSpec::SharedContext
    let(:step_into) { [] }

    # An alias for slightly more semantic meaning, just forces the lazy #subject to run.
    def run_chef
      subject
    end

    private

    def patch_module(mod, name, obj, &block)
      class_name = Chef::Mixin::ConvertToClassName.convert_to_class_name(name.to_s)
      if mod.const_defined?(class_name, false)
        old_class = mod.const_get(class_name, false)
        # We are only allowed to patch over things installed by patch_module
        raise "#{mod.name}::#{class_name} is already defined" if !old_class.instance_variable_get(:@poise_spec_helper)
        # Remove it before setting to avoid the redefinition warning
        mod.send(:remove_const, class_name)
      end
      # Tag our objects so we know we are allows to overwrite those, but not other stuff.
      obj.instance_variable_set(:@poise_spec_helper, true)
      mod.const_set(class_name, obj)
      begin
        block.call
      ensure
        # Same as above, have to remove before set because warnings
        mod.send(:remove_const, class_name)
        mod.const_set(class_name, old_class) if old_class
      end
    end

    module ClassMethods
      def recipe(&block)
        subject { HaliteRunner.new(step_into: step_into).converge(&block) }
      end

      def resource(name, options={}, &block)
        options = {auto: true, parent: Chef::Resource}.merge(options)
        # Create the resource class
        resource_class = Class.new(options[:parent]) do
          class_exec(&block) if block
          # Wrap some stuff around initialize because I'm lazy
          if options[:auto]
            old_init = instance_method(:initialize)
            define_method(:initialize) do |*args|
              # Fill in the resource name because I know it
              @resource_name = name.to_sym
              old_init.bind(self).call(*args)
              # ChefSpec doesn't seem to work well with action :nothing
              if @action == :nothing
                @action = :run
                @allowed_actions |= [:run]
              end
            end
          end
        end

        # Figure out the available actions
        resource_class.new(nil, nil).allowed_actions.each do |action|
          define_method("#{action}_#{name}") do |resource_name|
            ChefSpec::Matchers::ResourceMatcher.new(name, action, resource_name)
          end
        end

        around do |ex|
          # Automatically step in to our new resource
          step_into << name
          # Patch the resource in to Chef
          patch_module(Chef::Resource, name, resource_class) { ex.run }
        end
      end

      def provider(name, options={}, &block)
        options = {auto: true, rspec: true, parent: Chef::Provider}.merge(options)
        provider_class = Class.new(options[:parent]) do
          # Pull in RSpec expectations
          include RSpec::Matchers if options[:rspec]

          if options[:auto]
            # Default blank impl to avoid error
            def load_current_resource
            end

            # Blank action because I do that so much
            def action_run
            end
          end

          class_exec(&block) if block
        end

        around do |ex|
          patch_module(Chef::Provider, name, provider_class) { ex.run }
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

RSpec.configure do |config|
  # Basic configuraiton
  config.run_all_when_everything_filtered = true
  config.filter_run(:focus)

  # Run specs in random order to surface order dependencies. If you find an
  # order dependency and want to debug it, you can fix the order by providing
  # the seed, which is printed after each run.
  #     --seed 1234
  config.order = 'random'

  config.include Poise::SpecHelpers
end
