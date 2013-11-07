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

module Poise
  module Resource
    module LazyDefault
      module ClassMethods
        def lazy(&block)
          Chef::DelayedEvaluator.new(&block)
        end

        def included(klass)
          super
          klass.extend ClassMethods
        end
      end

      extend ClassMethods

      def set_or_return(symbol, arg, validation)
        if validation && validation[:default].is_a?(Chef::DelayedEvaluator)
          validation = validation.dup
          validation[:default] = instance_eval(&validation[:default])
        end
        super(symbol, arg, validation)
      end
    end
  end
end
