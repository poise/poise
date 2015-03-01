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

require 'spec_helper'
require 'poise/chefspec_matchers'

describe Poise::ChefspecMatchers do
  context 'with an implicit name' do
    resource(:poise_test, auto: false, step_into: false) do
      include Poise::ChefspecMatchers
      actions(:run)
    end
    recipe do
      poise_test 'test'
    end

    it { is_expected.to run_poise_test('test') }
  end # /context with an implicit name


  context 'with an explicit name' do
    resource(:poise_test, auto: false, step_into: false) do
      include Poise::ChefspecMatchers
      # HAXX because provides() gets cranky on anonymous classes.
      def self.constantize(name)
        if name == 'Chef::Resource::PoiseTest'
          self
        else
          super
        end
      end
      provides(:poise_other)
      actions(:run)
    end
    recipe do
      poise_other 'test'
    end

    it { is_expected.to run_poise_other('test') }
  end # /context with an explicit name
end
