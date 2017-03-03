#
# Copyright 2015-2016, Noah Kantrowitz
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

describe Poise::Helpers::ResourceCloning do
  resource(:poise_test) do
    def value(*args)
      set_or_return(:value, *args, {})
    end
  end
  provider(:poise_test)
  recipe do
    poise_test 'test' do
      value 1
    end

    poise_test 'test' do
      value 2
    end
  end

  if ::Gem::Requirement.create('< 13').satisfied_by?(::Gem::Version.create(Chef::VERSION))
    context 'with a resource that should be cloned' do
      # Baseline to make sure my test harness works.
      it do
        expect(Chef::Log).to receive(:warn).at_least(:once)
        run_chef
      end
    end # /context with a resource that should be cloned
  end

  context 'a resource using the helper' do
    resource(:poise_test) do
      include described_class
      def value(*args)
        set_or_return(:value, *args, {})
      end
    end
    it do
      expect(Chef::Log).to_not receive(:warn)
      run_chef
    end
  end # /context a resource using the helper
end
