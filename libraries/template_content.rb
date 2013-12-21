#
# Author:: Noah Kantrowitz <noah@coderanger.net>
#
# Copyright 2013, Noah Kantrowitz
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

require 'chef/provider/template_finder'
require 'chef/mixin/template'

require File.expand_path('../lazy_default', __FILE__)
require File.expand_path('../lwrp_polyfill', __FILE__)
require File.expand_path('../option_collector', __FILE__)

module Poise
  module Resource
    module TemplateContent
      include LazyDefault
      include LWRPPolyfill
      include OptionCollector

      module ClassMethods
        def attribute(name, options={})
          if options.delete(:template)
            name_prefix = name.empty? ? '' : "#{name}_"

            # If you are reading this, I'm so sorry
            # This is used for computing the default cookbook below
            parent_filename = caller.first.reverse.split(':', 4).last.reverse

            # Template source path if using a template
            attribute("#{name_prefix}source", kind_of: String)
            define_method("_#{name_prefix}source") do
              send("#{name_prefix}source") || options[:default_source]
            end

            # Template cookbook name if using a template
            attribute("#{name_prefix}cookbook", kind_of: [String, Symbol], default: lazy do
              # Use instance_variable_get since we need to know if it was
              # actually set or if it was from the default
              if send("#{name_prefix}source")
                cookbook_name
              elsif options[:default_cookbook]
                options[:default_cookbook]
              else
                Poise::Resource::TemplateContent._find_cookbook_file_filename(run_context, parent_filename)
              end
            end)

            # Template variables if using a template
            attribute("#{name_prefix}options", option_collector: true)

            # The big one, get/set content, but if you are getting and no
            # explicit content was given, try to render the template
            define_method("#{name_prefix}content") do |arg=nil|
              ret = set_or_return("#{name_prefix}content", arg, kind_of: String)
              if !ret && !arg
                # Some caching might be good here, but leaving that for another day
                ret = send("_#{name_prefix}content")
              end
              ret
            end

            # Validate that arguments work
            define_method("_#{name_prefix}validate") do
              # Use instance_variable_get to avoid triggering the actual render
              if options[:required] && !send("_#{name_prefix}source") && !instance_variable_get(:"@#{name_prefix}content")
                raise Chef::Exceptions::ValidationFailed, "#{self}: One of #{name_prefix}source or #{name_prefix}content is required"
              end
              if send("#{name_prefix}source") && instance_variable_get(:"@#{name_prefix}content")
                raise Chef::Exceptions::ValidationFailed, "#{self}: Only one of #{name_prefix}source or #{name_prefix}content can be specified"
              end
            end

            # Monkey patch #after_create to run best-effort validation. Arguments
            # could be changed after creation, but this gives nicer errors for
            # most cases.
            unless options[:no_validate_on_create]
              old_after_created = instance_method(:after_created)
              define_method(:after_created) do
                old_after_created.bind(self).call
                send("_#{name_prefix}validate")
              end
            end

            # Compile the needed content
            define_method("_#{name_prefix}content") do
              # Run validation again
              send("_#{name_prefix}validate")
              # Get all the relevant parameters
              content = instance_variable_get(:"@#{name_prefix}content")
              source = send("_#{name_prefix}source")
              default = options[:default]
              if content
                content
              elsif source
                cookbook = send("#{name_prefix}cookbook")
                template_options = send("#{name_prefix}options")
                send("_#{name_prefix}render_template", source, cookbook, template_options)
              elsif default
                default.is_a?(Chef::DelayedEvaluator) ? instance_eval(&default) : default
              end
            end

            # Actually render a template
            define_method("_#{name_prefix}render_template") do |source, cookbook, template_options|
              template_options.update(options[:template_options]) if options[:template_options]
              template_options[:new_resource] = self
              finder = Chef::Provider::TemplateFinder.new(run_context, cookbook, node)
              context = Chef::Mixin::Template::TemplateContext.new(template_options)
              context[:node] = node
              context[:template_finder] = finder
              context.render_template(finder.find(source))
            end
          else
            super if defined?(super)
          end
        end

        def included(klass)
          super
          klass.extend ClassMethods
        end
      end

      extend ClassMethods

      def self._find_cookbook_file_filename(run_context, filename)
        run_context.cookbook_collection.each do |name, ver|
          Chef::CookbookVersion::COOKBOOK_SEGMENTS.each do |seg|
            ver.segment_filenames(seg).each do |file|
              if file == filename
                return name
              end
            end
          end
        end
        raise Chef::Exceptions::ValidationFailed, "Unable to find cookbook for file '#{filename}'"
      end

    end
  end
end
