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

require File.expand_path('../subcontext_block', __FILE__)

module Poise
  module Provider
    module IncludeRecipe
      include SubContextBlock

      def include_recipe(*recipes)
        context = global_run_context
        subcontext = subcontext_block(context) do
          run_context.include_recipe(*recipes)
        end
        # Converge the new context.
        Chef::Runner.new(subcontext).converge
        subcontext.resource_collection.each do |r|
          context.resource_collection.insert(r)
        end
      end
    end
  end
end
