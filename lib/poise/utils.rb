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
    autoload :ResourceProviderMixin, 'poise/utils/resource_provider_mixin'

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
      possibles = {}
      Chef::Log.debug("[Poise] Checking cookbook for #{filename.inspect}")
      run_context.cookbook_collection.each do |name, ver|
        # This special method is added by Halite::Gem#as_cookbook_version.
        if ver.respond_to?(:halite_root)
          # The join is there because ../poise-ruby/lib starts with ../poise so
          # we want a trailing /.
          Chef::Log.debug("")
          if filename.start_with?(File.join(ver.halite_root, ''))
            Chef::Log.debug("[Poise] Found matching halite_root in #{name}: #{ver.halite_root.inspect}")
            possibles[ver.halite_root] = name
          end
        else
          Chef::CookbookVersion::COOKBOOK_SEGMENTS.each do |seg|
            ver.segment_filenames(seg).each do |file|
              # Put this behind an environment variable because it is verbose
              # even for normal debugging-level output.
              Chef::Log.debug("[Poise] Checking #{seg} in #{name}: #{file.inspect}") if ENV['POISE_DEBUG']
              if file == filename
                Chef::Log.debug("[Poise] Found matching #{seg} in #{name}: #{file.inspect}")
                possibles[file] = name
              end
            end
          end
        end
      end
      raise Poise::Error.new("Unable to find cookbook for file #{filename.inspect}") if possibles.empty?
      # Sort the items by matching path length, pick the name attached to the longest.
      possibles.sort_by{|key, value| key.length }.last[1]
    end
  end
end
