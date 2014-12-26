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

module Poise
  module Resource
    module OptionCollector
      class OptionEvalContext
        attr_reader :options

        def initialize(parent)
          @parent = parent
          @options = {}
        end

        def method_missing(method_sym, *args, &block)
          @parent.send(method_sym, *args, &block)
        rescue NameError
          value = args.first
          value ||= block
          method_sym = method_sym.to_s.chomp('=').to_sym
          options[method_sym] = value if value
          options[method_sym] ||= nil
        end
      end

      module ClassMethods
        def attribute(name, options={})
          is_option_collector = options.delete(:option_collector)
          if is_option_collector
            options[:default] ||= {}
            # Unlock LWRPBase.attribute, I don't care about Ruby 1.8. Worlds tiniest violin.
            define_method(name.to_sym) do |arg=nil, &block|
              iv_sym = :"@#{name}"

              value = instance_variable_get(iv_sym) || begin
                default = options[:default]
                default = instance_eval(&default) if default.is_a?(Chef::DelayedEvaluator) # Handle lazy{}
                default.dup # Dup because we are mutating below
              end
              if arg
                raise Exceptions::ValidationFailed, "Option #{name} must be a Hash" if arg && !arg.is_a?(Hash)
                # Should this and the update below be a deep merge?
                value.update(arg)
              end
              if block
                ctx = OptionEvalContext.new(self)
                ctx.instance_exec(&block)
                value.update(ctx.options)
              end
              instance_variable_set(iv_sym, value)
              value
            end
          else
            super
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
end
