require 'rspec'
require 'chefspec'
# require 'rspec/its'
# require 'simplecov'
# SimpleCov.start

require 'poise'

class HaliteRunner < ChefSpec::SoloRunner
  def self.converge(&block)
    new.tap do |instance|
      instance.converge(&block)
    end
  end

  def initialize(options = {})
    options[:cookbook_path] = '/Users/coderanger/src/poise/empty'
    super(options)
  end

  def converge(&block)
    super do
      recipe = Chef::Recipe.new(nil, nil, run_context)
      recipe.instance_exec(&block)
    end
  end
end

module Poise
  module SpecHelpers
    extend RSpec::SharedContext
    let(:step_into) { [] }

    private

    def patch_module(mod, name, obj, &block)
      class_name = Chef::Mixin::ConvertToClassName.convert_to_class_name(name.to_s)
      raise "#{mod.name}::#{class_name} is already defined" if mod.const_defined?(class_name, false)
      mod.const_set(class_name, obj)
      begin
        block.call
      ensure
        mod.send(:remove_const, class_name)
      end
    end

    module ClassMethods
      def recipe(&block)
        subject { HaliteRunner.new(step_into: step_into).converge(&block) }
      end

      def resource(name, &block)
        # Create the resource class
        resource_class = Class.new(Chef::Resource) do
          instance_exec(&block)
          # Wrap some stuff around initialize because I'm lazy
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

      def provider(name, &block)
        provider_class = Class.new(Chef::Provider) do
          # Default blank impl to avoid error
          def load_current_resource
          end

          # Blank action because I do that so much
          def action_run
          end

          instance_exec(&block) if block
        end

        around do |ex|
          patch_module(Chef::Provider, name, provider_class) { ex.run }
        end
      end
    end

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
  config.extend Poise::SpecHelpers::ClassMethods
end
