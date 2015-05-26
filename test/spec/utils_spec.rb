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

require 'spec_helper'
require 'chef/cookbook_version'

describe Poise::Utils do
  describe '.find_cookbook_name' do
    let(:cookbooks) { [] }
    let(:run_context) { instance_double('Chef::RunContext', cookbook_collection: cookbooks.inject({}) {|memo, ver| memo[ver.name] = ver; memo })}
    let(:filename) { '/test/my_cookbook/libraries/default.rb' }
    subject { described_class.find_cookbook_name(run_context, filename) }

    context 'with no cookbooks' do
      it { expect { subject }.to raise_error Poise::Error }
    end # /context with no cookbooks

    context 'with one cookbook' do
      before do
        cookbooks << Chef::CookbookVersion.new('my_cookbook', '/test/my_cookbook').tap do |ver|
          ver.library_filenames << '/test/my_cookbook/libraries/default.rb'
        end
      end
      it { is_expected.to eq 'my_cookbook' }
    end # /context with one cookbook

    context 'with many cookbooks' do
      before do
        cookbooks << Chef::CookbookVersion.new('other_cookbook', '/test/other_cookbook').tap do |ver|
          ver.library_filenames << '/test/other_cookbook/libraries/default.rb'
          ver.recipe_filenames << '/test/other_cookbook/recipe/default.rb'
        end
        cookbooks << Chef::CookbookVersion.new('my_cookbook', '/test/my_cookbook').tap do |ver|
          ver.library_filenames << '/test/my_cookbook/libraries/default.rb'
          ver.recipe_filenames << '/test/my_cookbook/recipe/default.rb'
        end
      end
      it { is_expected.to eq 'my_cookbook' }
    end # /context with many cookbooks

    context 'with many non-matching cookbooks' do
      before do
        cookbooks << Chef::CookbookVersion.new('other_cookbook', '/test/other_cookbook').tap do |ver|
          ver.library_filenames << '/test/other_cookbook/libraries/default.rb'
          ver.recipe_filenames << '/test/other_cookbook/recipe/default.rb'
        end
        cookbooks << Chef::CookbookVersion.new('my_cookbook', '/test/my_cookbook').tap do |ver|
          ver.recipe_filenames << '/test/my_cookbook/recipe/default.rb'
        end
      end
      it { expect { subject }.to raise_error Poise::Error }
    end # /context with many non-matching cookbooks

    context 'with a Halite cookbook' do
      let(:filename) { '/source/halite_cookbook/lib/something.rb' }
      before do
        cookbooks << Chef::CookbookVersion.new('other_cookbook', '/test/other_cookbook').tap do |ver|
          ver.library_filenames << '/test/other_cookbook/libraries/default.rb'
          ver.recipe_filenames << '/test/other_cookbook/recipe/default.rb'
        end
        cookbooks << Chef::CookbookVersion.new('halite_cookbook', '/test/halite_cookbook').tap do |ver|
          def ver.halite_root
            '/source/halite_cookbook'
          end
        end
        cookbooks << Chef::CookbookVersion.new('my_cookbook', '/test/my_cookbook').tap do |ver|
          ver.recipe_filenames << '/test/my_cookbook/recipe/default.rb'
        end
      end
      it { is_expected.to eq 'halite_cookbook' }
    end # /context with a Halite cookbook

    context 'with a Halite cookbook on a shared prefix' do
      let(:filename) { '/source/halite_cookbook_other/lib/something.rb' }
      before do
        cookbooks << Chef::CookbookVersion.new('other_cookbook', '/test/other_cookbook').tap do |ver|
          ver.library_filenames << '/test/other_cookbook/libraries/default.rb'
          ver.recipe_filenames << '/test/other_cookbook/recipe/default.rb'
        end
        cookbooks << Chef::CookbookVersion.new('halite_cookbook', '/test/halite_cookbook').tap do |ver|
          def ver.halite_root
            '/source/halite_cookbook'
          end
        end
        cookbooks << Chef::CookbookVersion.new('halite_cookbook_other', '/test/halite_cookbook_other').tap do |ver|
          def ver.halite_root
            '/source/halite_cookbook_other'
          end
        end
        cookbooks << Chef::CookbookVersion.new('my_cookbook', '/test/my_cookbook').tap do |ver|
          ver.recipe_filenames << '/test/my_cookbook/recipe/default.rb'
        end
      end
      it { is_expected.to eq 'halite_cookbook_other' }
    end # /context with a Halite cookbook on a shared prefix

    context 'with a Halite cookbook on a nested prefix' do
      let(:filename) { '/source/halite_cookbook/vendor/other/lib/something.rb' }
      before do
        cookbooks << Chef::CookbookVersion.new('other_cookbook', '/test/other_cookbook').tap do |ver|
          ver.library_filenames << '/test/other_cookbook/libraries/default.rb'
          ver.recipe_filenames << '/test/other_cookbook/recipe/default.rb'
        end
        cookbooks << Chef::CookbookVersion.new('halite_cookbook', '/test/halite_cookbook').tap do |ver|
          def ver.halite_root
            '/source/halite_cookbook'
          end
        end
        cookbooks << Chef::CookbookVersion.new('halite_cookbook_other', '/test/halite_cookbook/vendor/other').tap do |ver|
          def ver.halite_root
            '/source/halite_cookbook/vendor/other'
          end
        end
        cookbooks << Chef::CookbookVersion.new('my_cookbook', '/test/my_cookbook').tap do |ver|
          ver.recipe_filenames << '/test/my_cookbook/recipe/default.rb'
        end
      end
      it { is_expected.to eq 'halite_cookbook_other' }
    end # /context with a Halite cookbook on a nested prefix
  end # /describe .find_cookbook_name
end
