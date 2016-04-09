#
# Copyright 2016, Noah Kantrowitz
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


module Poise
  module Utils
    module Win32
      extend self

      # Code borrowed from https://github.com/chef-cookbooks/chef-client/blob/master/libraries/helpers.rb
      # Used under the terms of the Apache v2 license.
      # Copyright 2012-2016, John Dewey

      # Run a WMI query and extracts a property. This assumes Chef has already
      # loaded the win32 libraries.
      #
      # @api private
      # @param wmi_property [Symbol] Property to extract.
      # @param wmi_query [String] Query to run.
      # @return [String]
      def wmi_property_from_query(wmi_property, wmi_query)
        @wmi = ::WIN32OLE.connect('winmgmts://')
        result = @wmi.ExecQuery(wmi_query)
        return nil unless result.each.count > 0
        result.each.next.send(wmi_property)
      end

      # Find the name of the Administrator user, give or take localization.
      #
      # @return [String]
      def admin_user
        wmi_property_from_query(:name, "select * from Win32_UserAccount where sid like 'S-1-5-21-%-500' and LocalAccount=True")
      end

    end
  end
end
