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

require 'chef/resource'

require 'poise/error'


module Poise
  module Helpers
    module Subresources
      # A resource mixin for child subresources.
      #
      # @since 1.0.0
      module Child
        # Little class used to fix up the display of subresources in #to_text.
        # Without this you get the full parent resource shown for @parent et al.
        # @api private
        class ParentRef
          attr_accessor :resource

          def initialize(resource)
            @resource = resource
          end

          def to_text
            @resource.to_s
          end
        end

        # @overload parent()
        #   Get the parent resource for this child. This may be nil if the
        #   resource is set to parent_optional = true.
        #   @return [Chef::Resource, nil]
        # @overload parent(val)
        #   Set the parent resource. The parent can be set as  resource
        #   object, a string (either a bare resource name or a type[name]
        #   string), or a type:name hash.
        #   @param val [String, Hash, Chef::Resource] Parent resource to set.
        #   @return [Chef::Resource, nil]
        def parent(val=nil)
          _parent(:parent, self.class.parent_type, self.class.parent_optional, val)
        end

        # Register ourself with parents in case this is not a nested resource.
        #
        # @api private
        def after_created
          super
          self.class.parent_attributes.each do |name|
            parent = self.send(name)
            parent.register_subresource(self) if parent
          end
        end

        private

        # Generic form of the parent getter/setter.
        #
        # @since 2.0.0
        # @see #parent
        def _parent(name, parent_type, parent_optional, val=nil)
          # Allow using a DSL symbol as the parent type.
          if parent_type.is_a?(Symbol)
            parent_type = Chef::Resource.resource_for_node(parent_type, node)
          end
          # Grab the ivar for local use.
          parent = instance_variable_get(:"@#{name}")
          if val
            if val.is_a?(String) && !val.include?('[')
              raise Poise::Error.new('Cannot use a string parent without defining a parent type') if parent_type == Chef::Resource
              val = "#{parent_type.resource_name}[#{val}]"
            end
            if val.is_a?(String) || val.is_a?(Hash)
              val = @run_context.resource_collection.find(val)
            end
            if !val.is_a?(parent_type)
              raise Poise::Error.new("Parent resource is not an instance of #{parent_type.name}: #{val.inspect}")
            end
            parent = ParentRef.new(val)
          elsif !parent
            # Automatic sibling lookup for sequential composition.
            # Find the last instance of the parent class as the default parent.
            # This is super flaky and should only be a last resort.
            @run_context.resource_collection.each do |r|
              if r.is_a?(parent_type)
                parent = ParentRef.new(r)
              end
            end
            # Can't find a valid parent, if it wasn't optional raise an error.
            raise Poise::Error.new("No parent found for #{self}") unless parent || parent_optional
          end
          # Store the ivar back.
          instance_variable_set(:"@#{name}", parent)
          # Return the actual resource.
          parent && parent.resource
        end

        module ClassMethods
          # @overload parent_type()
          #   Get the class of the default parent link on this resource.
          #   @return [Class, Symbol]
          # @overload parent_type(type)
          #   Set the class of the default parent link on this resource.
          #   @param type [Class, Symbol] Class to set.
          #   @return [Class, Symbol]
          def parent_type(type=nil)
            if type
              raise Poise::Error.new("Parent type must be a class or symbol, got #{type.inspect}") unless type.is_a?(Class) || type.is_a?(Symbol)
              @parent_type = type
            end
            @parent_type || (superclass.respond_to?(:parent_type) ? superclass.parent_type : Chef::Resource)
          end

          # @overload parent_optional()
          #   Get the optional mode for the default parent link on this resource.
          #   @return [Boolean]
          # @overload parent_optional(val)
          #   Set the optional mode for the default parent link on this resource.
          #   @param val [Boolean] Mode to set.
          #   @return [Boolean]
          def parent_optional(val=nil)
            unless val.nil?
              @parent_optional = val
            end
            if @parent_optional.nil?
              superclass.respond_to?(:parent_optional) ? superclass.parent_optional : false
            else
              @parent_optional
            end
          end

          # Create a new kind of parent link.
          #
          # @since 2.0.0
          # @param name [Symbol] Name of the relationship. This becomes a method
          #   name on the resource instance.
          # @param parent_type [Class] Class of the parent.
          # @param parent_optional [Boolean] If the parent is optional.
          # @return [void]
          def parent_attribute(name, parent_type=Chef::Resource, parent_optional=false)
            name = :"parent_#{name}"
            (@parent_attributes ||= []) << name
            define_method(name) do |val=nil|
              _parent(name, parent_type, parent_optional, val)
            end
          end

          # Return the name of all parent relationships on this class.
          #
          # @since 2.0.0
          # @return [Array<Symbol>]
          def parent_attributes
            [:parent].tap do |attrs| # Always
              attrs += Array(@parent_attributes) # Local
              attrs += superclass.parent_attributes if superclass.respond_to?(:parent_attributes) # Superclass?
              attrs.uniq! # De-dup
            end
          end

          # @api private
          def included(klass)
            super
            klass.extend(ClassMethods)
          end
        end

        extend ClassMethods
      end
    end
  end
end
