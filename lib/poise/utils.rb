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

require 'poise/error'


module Poise
  module Utils
    extend self

    # Find the cookbook name for a given filename. The can used to find the
    # cookbook that corresponds to a caller of a file.
    #
    # @param run_context [Chef::RunContext] Context to check.
    # @param filename [String] Absolute filename to check for.
    # @return [String]
    # @example
    #   def my_thing
    #     caller_filename = caller.first.split(':').first
    #     cookbook = Poise::Utils.find_cookbook_name(run_context, caller_filename)
    #     # ...
    #   end
    def find_cookbook_name(run_context, filename)
      run_context.cookbook_collection.each do |name, ver|
        Chef::CookbookVersion::COOKBOOK_SEGMENTS.each do |seg|
          ver.segment_filenames(seg).each do |file|
            if file == filename
              return name
            end
          end
        end
      end
      raise Poise::Error.new("Unable to find cookbook for file #{filename.inspect}")
    end
  end
end
