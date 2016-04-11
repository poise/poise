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

describe Poise::Helpers::IncludeRecipe do
  resource(:poise_test)
  recipe do
    poise_test 'test'
  end

  context 'with a string' do
    provider(:poise_test) do
      include described_class

      def action_run
        include_recipe 'other'
      end
    end

    it do
      expect_any_instance_of(Chef::RunContext).to receive(:include_recipe).with('other').and_return(['other::default'])
      run_chef
    end
  end # /context with a string

  context 'with a proc' do
    provider(:poise_test) do
      include described_class

      def action_run
        include_recipe proc { node.run_state['proc1'] = true }
      end
    end

    it do
      run_chef
      expect(chef_run.node.run_state['proc1']).to be true
    end
  end # /context with a proc

  context 'with an multiple arguments' do
    provider(:poise_test) do
      include described_class

      def action_run
        include_recipe('other', proc { node.run_state['proc2'] = true })
      end
    end

    it do
      expect_any_instance_of(Chef::RunContext).to receive(:include_recipe).with('other').and_return(['other::default'])
      run_chef
      expect(chef_run.node.run_state['proc2']).to be true
    end
  end # /context with an multiple arguments

  context 'with an array' do
    provider(:poise_test) do
      include described_class

      def action_run
        include_recipe ['other', proc { node.run_state['proc3'] = true }]
      end
    end

    it do
      expect_any_instance_of(Chef::RunContext).to receive(:include_recipe).with('other').and_return(['other::default'])
      run_chef
      expect(chef_run.node.run_state['proc3']).to be true
    end
  end # /context with an array

  context 'via include Poise' do
    provider(:poise_test) do
      include Poise

      def action_run
        include_recipe ['other', proc { node.run_state['proc4'] = true }]
      end
    end

    it do
      expect_any_instance_of(Chef::RunContext).to receive(:include_recipe).with('other').and_return(['other::default'])
      run_chef
      expect(chef_run.node.run_state['proc4']).to be true
    end
  end # /context via include Poise
end
