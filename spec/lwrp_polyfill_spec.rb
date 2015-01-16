require 'spec_helper'

describe Poise::Resource::LWRPPolyfill do
  resource(:poise_test) do
    include Poise::Resource::LWRPPolyfill
    attribute(:boolean, equal_to: [true, false])
  end

  provider(:poise_test)

  context 'with default value' do
    recipe do
      poise_test 'nil'
    end

    it { is_expected.to run_poise_test('nil').with(boolean: nil) }
  end

  context 'with true value' do
    recipe do
      poise_test 'true' do
        boolean true
      end
    end

    it { is_expected.to run_poise_test('true').with(boolean: true) }
  end

  context 'with false value' do
    recipe do
      poise_test 'false' do
        boolean false
      end
    end

    it { is_expected.to run_poise_test('false').with(boolean: false) }
  end

  context 'with string value' do
     recipe do
      poise_test 'true' do
        boolean 'boom'
      end
    end

    it { expect { subject }.to raise_error Chef::Exceptions::ValidationFailed }
  end

end
