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

require 'chef/dsl/recipe'
require 'chef/mixin/convert_to_class_name'

require File.expand_path('../subcontext_block', __FILE__)

module Poise
  module Resource
    # Hide the output a bit
    class NoPrintingResourceCollection < Chef::ResourceCollection
      def to_text
        "[#{all_resources.map(&:to_s).join(', ')}]"
      end
    end

    module SubResourceContainer
      include SubContextBlock
      include Chef::DSL::Recipe

      attr_reader :subresources

      def initialize(*args)
        super
        @subresources = NoPrintingResourceCollection.new
      end

      def after_created
        super
        unless @subresources.empty?
          Chef::Log.debug("#{self}: Adding subresources to collection:")
          # Because after_create is run before adding the container to the resource collection
          # we need to jump through some hoops to get it swapped into place.
          self_ = self
          noop = Chef::Resource::RubyBlock.new('subresource_noop', @run_context)
          noop.action(:nothing)
          order_fixer = Chef::Resource::RubyBlock.new('subresource_order_fixer', @run_context)
          order_fixer.block do
            col = self_.run_context.resource_collection
            # Overwrite the current location of the container with a NOOP.
            # I'm unthrilled about needing this extra resource, but I can't find
            # a way around it right now.
            col.each_index do |i|
              if col[i] === self_
                col[i] = noop
                break
              end
            end
            # Replace this resource with the container and step the iterator back.
            col.each_index do |i|
              if col[i] === order_fixer
                col[i] = self_
                col.iterator.skip_back
                break
              end
            end
          end
          @run_context.resource_collection.insert(order_fixer)
          @subresources.each do |r|
            Chef::Log.debug("   * #{r}")
            @run_context.resource_collection.insert(r)
          end
        end
      end

      def method_missing(method_symbol, name=nil, &block)
        return super unless name # Generally some kind of error
        Chef::Log.debug("#{self}: Creating subresource from #{method_symbol}(#{name})")
        self_ = self
        # Run this inside a subcontext to avoid adding to the current resource collection.
        # It will end up added later, indirected via @subresources to ensure ordering.
        subcontext_block do
          super(method_symbol, "#{self.name}::#{name}") do
            # Apply the correct parent before anything else so it is available
            # in after_created for the subresource.
            parent(self_)
            instance_exec(&block) if block
          end
        end
      end

      private

      # Thanks Array.flatten, big help you are.
      def to_ary
        nil
      end

    end

    module SubResource
      # Little class used to fix up the display of subresources in #to_text
      class ParentRef
        attr_accessor :resource

        def initialize(resource)
          @resource = resource
        end

        def to_text
          @resource.to_s
        end
      end

      module ClassMethods
        def parent_type(type=nil)
          if type
            raise "Parent type must be a class" unless type.is_a?(Class)
            @parent_type = type
          end
          @parent_type || (superclass.respond_to?(:parent_type) ? superclass.parent_type : [Chef::Resource])
        end

        def parent_optional(value=nil)
          unless value.nil?
            @parent_optional = value
          end
          if @parent_optional.nil?
            superclass.respond_to?(:parent_type) ? superclass.parent_type : false
          else
            @parent_optional
          end
        end

        def included(klass)
          super
          klass.extend ClassMethods
        end
      end

      extend ClassMethods

      def parent(arg=nil)
        if arg
          if arg.is_a?(String) && !arg.includes?('[')
             parent_class_name = Chef::Mixin::ConvertToClassName.convert_to_snake_case(self.class.parent_type.name, 'Chef::Resource')
             arg = "#{parent_class_name}[#{arg}]"
          end
          if arg.is_a?(String) || arg.is_a?(Hash)
            arg = @run_context.resource_collection.find(arg)
          elsif !arg.is_a?(self.class.parent_type)
            raise "Unknown parent resource: #{arg}"
          end
          @parent = ParentRef.new(arg)
        elsif !@parent
          # Find the last instance of the parent class as the default parent
          @run_context.resource_collection.each do |r|
            if r.is_a?(self.class.parent_type)
              @parent = ParentRef.new(r)
            end
          end
          raise "No parent found for #{self}" unless @parent || self.class.parent_optional
        end
        @parent && @parent.resource
      end

      def after_created
        super
        begin
          parent.subresources.lookup(self) if parent
        rescue Chef::Exceptions::ResourceNotFound
          Chef::Log.debug("#{self}: Adding to subresources of #{parent}")
          parent.subresources.insert(self)
        end
      end
    end
  end
end
