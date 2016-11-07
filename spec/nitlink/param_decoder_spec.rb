require 'spec_helper'
require 'nitlink/param_decoder'

RSpec.describe Nitlink::ParamDecoder do
  let(:decoder) { described_class.new }

  describe '#decode' do
    it 'decodes a percent encoded value' do
      expect(decoder.decode "UTF-8''%c2%a3%20and%20%e2%82%ac%20rates").to eq '£ and € rates'
    end

    it 'treats the charset case-insensitively' do
      expect(decoder.decode "utf-8''%c2%a3%20and%20%e2%82%ac%20rates").to eq '£ and € rates'
    end

    it 'throws an error for a different charset' do
      expect { decoder.decode("utf-9''%c2%a3%20rates") }.to raise_error(Nitlink::UnsupportedCharsetError, /invalid charset/i)
    end

    it 'allows a language to be provided' do
      expect(decoder.decode "UTF-8'en'%c2%a3%20and%20%e2%82%ac%20rates").to eq '£ and € rates'
    end

    it 'throws an error for a malformed encoded value' do
      expect { decoder.decode("utf-8%c2%a3%20rates") }.to raise_error(Nitlink::EncodedParamSyntaxError, /syntax error/i)
    end
  end
end