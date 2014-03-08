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

require File.expand_path('../subcontext_block', __FILE__)

module Poise
  module Provider
    module NotifyingBlock
      include SubContextBlock

      private
      def notifying_block(&block)
        # Make sure to mark the resource as updated-by-last-action if
        # any sub-run-context resources were updated (any actual
        # actions taken against the system) during the
        # sub-run-context convergence.
        begin
          subcontext = subcontext_block(&block)
          # Converge the new context.
          Poise::SubRunner.new(new_resource, subcontext).converge
        ensure
          new_resource.updated_by_last_action(
            subcontext && subcontext.resource_collection.any?(&:updated?)
          )
        end
      end
    end
  end
end
