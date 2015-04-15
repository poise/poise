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

require 'chef/resource_collection'


module Poise
  module Subcontext
    # A subclass of the normal Chef ResourceCollection that creates a partially
    # isolated set of resources. Notifications and other resources lookups can
    # propagate out to parent contexts but not back in. This is used to allow
    # black-box resources that are still aware of things in upper contexts.
    #
    # @api private
    # @since 1.0.0
    class ResourceCollection < Chef::ResourceCollection
      attr_accessor :parent

      def initialize(parent)
        @parent = parent
        super()
      end

      def lookup(resource)
        super
      rescue Chef::Exceptions::ResourceNotFound
        @parent.lookup(resource)
      end

      # Iterate and expand all nested contexts
      def recursive_each(&block)
        if @parent
          if @parent.respond_to?(:recursive_each)
            @parent.recursive_each(&block)
          else
            @parent.each(&block)
          end
        end
        each(&block)
      end
    end
  end
end
