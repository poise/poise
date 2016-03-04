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
require 'etc'

describe Poise::Utils::ShellOut do
  let(:arg) { double('command argument') }
  let(:cmd) { double('Mixlib::ShellOut') }

  describe '.poise_shell_out' do
    let(:user_ent) { double('Passwd', name: 'testuser', uid: 500, gid: 501) }
    let(:command_args) { [arg] }
    let(:expect_args) { [arg, {environment: {}}] }
    before do
      allow(Etc).to receive(:getpwuid).with(500).and_return(user_ent)
      allow(Etc).to receive(:getpwnam).with('testuser').and_return(user_ent)
      allow(Dir).to receive(:home).with('testuser').and_return('/home/testuser')
      expect(described_class).to receive(:shell_out).with(*expect_args).and_return(cmd)
    end
    subject { described_class.poise_shell_out(*command_args) }

    context 'with no user' do
      it { is_expected.to be cmd }
    end # /context with no user

    context 'with a user' do
      let(:command_args) { [arg, {user: 'testuser'}] }
      let(:expect_args) { [arg, {user: 'testuser', group: 501, environment: {'HOME' => '/home/testuser', 'USER' => 'testuser', 'LOGNAME' => 'testuser'}}] }
      it { is_expected.to be cmd }
    end # /context with a user

    context 'with a uid' do
      let(:command_args) { [arg, {user: 500}] }
      let(:expect_args) { [arg, {user: 500, group: 501, environment: {'HOME' => '/home/testuser', 'USER' => 'testuser', 'LOGNAME' => 'testuser'}}] }
      it { is_expected.to be cmd }
    end # /context with a uid

    context 'with a group' do
      let(:command_args) { [arg, {user: 'testuser', group: 'othergroup'}] }
      let(:expect_args) { [arg, {user: 'testuser', group: 'othergroup', environment: {'HOME' => '/home/testuser', 'USER' => 'testuser', 'LOGNAME' => 'testuser'}}] }
      it { is_expected.to be cmd }
    end # /context with a group

    context 'with a $HOME' do
      let(:command_args) { [arg, {user: 'testuser', environment: {'HOME' => '/other'}}] }
      let(:expect_args) { [arg, {user: 'testuser', group: 501, environment: {'HOME' => '/other', 'USER' => 'testuser', 'LOGNAME' => 'testuser'}}] }
      it { is_expected.to be cmd }
    end # /context with a $HOME

    context 'with a $USER' do
      let(:command_args) { [arg, {user: 'testuser', environment: {'USER' => 'other'}}] }
      let(:expect_args) { [arg, {user: 'testuser', group: 501, environment: {'HOME' => '/home/testuser', 'USER' => 'other', 'LOGNAME' => 'other'}}] }
      it { is_expected.to be cmd }
    end # /context with a $USER

    context 'with a bad user' do
      let(:command_args) { [arg, {user: 'testuser'}] }
      let(:expect_args) { [arg, {user: 'testuser', environment: {}}] }
      before do
        allow(Etc).to receive(:getpwnam).with('testuser').and_raise(ArgumentError)
      end
      it { is_expected.to be cmd }
    end # /context with a bad user

    context 'with an env option' do
      let(:command_args) { [arg, {user: 'testuser', env: {FOO: 'BAR'}}] }
      let(:expect_args) { [arg, {user: 'testuser', group: 501, environment: {'HOME' => '/home/testuser', 'USER' => 'testuser', 'LOGNAME' => 'testuser', 'FOO' => 'BAR'}}] }
      it { is_expected.to be cmd }
    end # /context with an env option

    context 'on Windows' do
      let(:command_args) { [arg, {user: 'testuser'}] }
      let(:expect_args) { [arg, {user: 'testuser', environment: {}}] }
      before do
        allow(Etc).to receive(:getpwnam).with('testuser').and_return(nil)
      end
      it { is_expected.to be cmd }
    end # /context on Windows
  end # /describe .poise_shell_out

  describe '.poise_shell_out!' do
    subject { described_class.poise_shell_out!(arg) }

    it do
      expect(described_class).to receive(:poise_shell_out).with(arg).and_return(cmd)
      expect(cmd).to receive(:error!)
      is_expected.to be cmd
    end
  end # /describe .poise_shell_out!
end
