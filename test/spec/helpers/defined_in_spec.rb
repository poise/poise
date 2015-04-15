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

describe Poise::Helpers::DefinedIn do
  let(:run_context) { double('run context') }
  subject { resource(:poise_test) }
  resource(:poise_test) do
    include described_class
  end

  describe '.included' do
    its(:poise_defined_in) { is_expected.to eq __FILE__ }
  end # /describe .included

  describe '.inherited' do
    subject { resource(:poise_test_inner) }
    resource(:poise_test_inner, parent: :poise_test)

    # The actual class creation happens up in the Halite spec helper.
    its(:poise_defined_in) { is_expected.to end_with '/lib/halite/spec_helper.rb' }
  end # /describe .inherited

  describe '.poise_defined_in_cookbook' do
    context 'with the default file' do
      it do
        expect(subject).to receive(:poise_defined_in).and_return('/src.rb')
        expect(Poise::Utils).to receive(:find_cookbook_name).with(run_context, '/src.rb').and_return('cookbook')
        expect(subject.poise_defined_in_cookbook(run_context)).to eq 'cookbook'
      end
    end # /context with the default file

    context 'with a specific file' do
      it do
        expect(Poise::Utils).to receive(:find_cookbook_name).with(run_context, '/other.rb').and_return('cookbook')
        expect(subject.poise_defined_in_cookbook(run_context, '/other.rb')).to eq 'cookbook'
      end
    end # /context with a specific file
  end # /describe .poise_defined_in_cookbook

  describe '#poise_defined_in_cookbook' do
    subject { resource(:poise_test).new('test', run_context) }
    it do
      expect(subject.class).to receive(:poise_defined_in_cookbook).with(run_context, '/other.rb').and_return('cookbook')
      expect(subject.poise_defined_in_cookbook('/other.rb')).to eq 'cookbook'
    end
  end # /describe #poise_defined_in_cookbook
end
