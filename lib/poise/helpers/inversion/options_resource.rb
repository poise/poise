#
# Copyright 2015, Noah Kantrowitz
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

require 'chef/mash'


module Poise
  module Helpers
    module Inversion
      # A mixin for inversion options resources.
      #
      # @api private
      # @since 2.0.0
      # @see Poise::Helper::Inversion
      module OptionsResource
        # @api private
        def self.included(klass)
          klass.class_exec do
            include Poise
            actions(:run)
            attribute(:resource, kind_of: String, name_attribute: true)
            attribute(:for_provider, kind_of: [String, Symbol], default: '*')
            attribute(:_options, kind_of: Hash, default: lazy { Mash.new })
          end
        end

        # Method missing delegation to allow DSL-style options.
        #
        # @example
        #   my_app_options 'app' do
        #     key1 'value1'
        #     key2 'value2'
        #   end
        def method_missing(*args, &block)
          super(*args, &block)
        rescue NoMethodError
          key, val = args
          val ||= block
          raise unless val
          _options[key] = val
        end

        # Insert the options data in to the run state. This has to match the
        # layout used in {Inversion::Provider.inversion_options}.
        #
        # @api private
        def after_created
          node.run_state['poise_inversion'] ||= {}
          node.run_state['poise_inversion'][resource] ||= {}
          node.run_state['poise_inversion'][resource][for_provider] ||= {}
          node.run_state['poise_inversion'][resource][for_provider].update(_options)
        end
      end
    end
  end
end
