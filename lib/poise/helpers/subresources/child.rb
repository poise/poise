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

require 'chef/mixin/convert_to_class_name'

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
          if val
            if val.is_a?(String) && !val.includes?('[')
              raise Poise::Error.new('Cannot use a string parent without defining a parent type') if self.class.parent_type == Chef::Resource
              val = "#{self.class.parent_type.resource_name}[#{val}]"
            end
            if val.is_a?(String) || val.is_a?(Hash)
              val = @run_context.resource_collection.find(val)
            elsif !val.is_a?(self.class.parent_type)
              raise Poise::Error.new("Unknown parent resource: #{val}")
            end
            @parent = ParentRef.new(val)
          elsif !@parent
            # Find the last instance of the parent class as the default parent
            @run_context.resource_collection.each do |r|
              if r.is_a?(self.class.parent_type)
                @parent = ParentRef.new(r)
              end
            end
            raise Poise::Error.new("No parent found for #{self}") unless @parent || self.class.parent_optional
          end
          @parent && @parent.resource
        end

        # Register ourself with the parent in case this is not a nested resource.
        #
        # @api private
        def after_created
          super
          parent.register_subresource(self) if parent
        end

        # @!classmethods
        module ClassMethods
          def parent_type(type=nil)
            if type
              raise "Parent type must be a class" unless type.is_a?(Class)
              @parent_type = type
            end
            @parent_type || (superclass.respond_to?(:parent_type) ? superclass.parent_type : Chef::Resource)
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
            klass.extend(ClassMethods)
          end
        end

        extend ClassMethods
      end
    end
  end
end
