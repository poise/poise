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

require 'spec_helper'
require 'shellwords'

describe Poise::Utils::Win32 do
  describe '#argv_quote' do
    let(:input) { }
    let(:force_quote) { false }
    subject { described_class.argv_quote(input, force_quote: force_quote) }

    context 'with an empty string' do
      let(:input) { '' }
      it { is_expected.to eq '""' }
    end # /context with an empty string

    context 'with one word' do
      let(:input) { 'foo' }
      it { is_expected.to eq 'foo' }
    end # /context with one word

    context 'with two words' do
      let(:input) { 'foo bar' }
      it { is_expected.to eq '"foo bar"' }
    end # /context with two words

    context 'with a quote' do
      let(:input) { 'foo"bar' }
      it { is_expected.to eq '"foo\\"bar"' }
    end # /context with a quote

    context 'with an escaped quote' do
      let(:input) { '"foo \\"bar\\""' }
      it { is_expected.to eq '"\\"foo \\\\\\"bar\\\\\\"\\""' }
    end # /context with an escaped quote
  end # /describe #argv_quote

  describe 'reparse_command' do
    let(:input) { [] }
    subject { described_class.reparse_command(*input) }

    context 'with a simple string' do
      let(:input) { ['foo bar baz'] }
      it { is_expected.to eq 'foo bar baz' }
    end # /context with a simple string

    context 'with a more complex string' do
      let(:input) { [Shellwords.join(['pip', 'install', 'foo==1.2.3'])] }
      it { is_expected.to eq 'pip install foo==1.2.3' }
    end # /context with a more complex string

    context 'with a quoted string' do
      let(:input) { [Shellwords.join(['myapp', 'create', 'a thing'])] }
      it { is_expected.to eq 'myapp create "a thing"' }
    end # /context with a quoted string

    context 'with metacharacters' do
      let(:input) { ['myapp > tmp'] }
      it { is_expected.to eq 'myapp > tmp' }
    end # /context with metacharacters

    context 'with an array' do
      let(:input) { ['myapp', 'create', 'a thing'] }
      it { is_expected.to eq 'myapp create "a thing"' }
    end # /context with an array

    context 'with an array with metacharacters' do
      let(:input) { ['myapp', '>', 'tmp'] }
      it { is_expected.to eq '^m^y^a^p^p^ ^>^ ^t^m^p' }
    end # /context with an array with metacharacters
  end # /describe reparse_command
end
