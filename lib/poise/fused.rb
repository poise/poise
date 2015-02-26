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

require 'chef/provider'

module Poise
  module Resource
    # Mixin to create "fused" resources where the resource and provider are
    # implemented in the same class.
    #
    # @since 1.1.0
    # @example
    #   class Chef::Resource::MyResource < Chef::Resource
    #     include Poise(fused: true)
    #     attribute(:path, kind_of: String)
    #     attribute(:message, kind_of: String)
    #     action(:run) do
    #       file new_resource.path do
    #         content new_resource.message
    #       end
    #     end
    #   end
    module Fused

      # Hack is_a? so that the DSL will consider this a Provider for the
      # purposes of attaching enclosing_provider.
      #
      # @!visibility private
      def is_a?(klass)
        if klass == Chef::Provider
          # Lies, damn lies, and Ruby code.
          true
        else
          super
        end
      end

      # Hack provider_for_action so that the resource is also the provider.
      #
      # @!visibility private
      def provider_for_action(action)
        unless provider
          fused_action = self.class.fused_actions[action.to_sym]
          fused_provider = Class.new(Chef::Provider) do
            include Poise
            define_method(:"action_#{action}", &fused_action)
          end
          provider(fused_provider)
        end
        super
      end

      # @!classmethods
      module ClassMethods
        # Define a provider action. The block should contain the usual provider
        # code.
        #
        # @param name [Symbol] Name of the action.
        # @param block [Proc] Action implementation.
        # @example
        #   action(:run) do
        #     file '/temp' do
        #       user 'root'
        #       content 'temp'
        #     end
        #   end
        def action(name, &block)
          fused_actions[name.to_sym] = block
        end

        # @!visibility private
        def fused_actions
          (@fused_actions ||= {})
        end

        # @!visibility private
        def included(klass)
          super
          klass.extend ClassMethods
        end
      end

      extend ClassMethods
    end
  end
end
