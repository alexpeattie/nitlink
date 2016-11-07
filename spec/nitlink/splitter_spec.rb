require 'spec_helper'
require 'nitlink/splitter'

RSpec.describe Nitlink::Splitter do
  let(:splitter) { described_class.new(@string) }
  before { @bs = "\\" }

  describe '#split_on_unquoted' do

    it 'returns an empty string unchanged' do
      @string = ''
      expect(splitter.split_on_unquoted ';').to eq [@string]
    end

    it 'splits on the separator given no quotes' do
      @string = '</hello>, </world>'
      expect(splitter.split_on_unquoted ',').to eq ['</hello>', ' </world>']
    end

    it "doesn't split when the separator is enclosed by quotes" do
      @string = '</hello> title=";" rel=next'
      expect(splitter.split_on_unquoted ';').to eq [@string]
    end

    it "doesn't consider a section to be quoted if there is no closing quote" do
      @string = '</hello> title=";" rel="next;crossorigin'
      expect(splitter.split_on_unquoted ';').to eq ['</hello> title=";" rel="next', 'crossorigin']
    end

    it "doesn't split inside URLs (within < >)" do
      @string = '</hello,world>, </bye>'
      expect(splitter.split_on_unquoted ',').to eq ['</hello,world>', ' </bye>']
    end

    it "doesn't split on params containing < or >" do
      @string = '</hello>; <foo=bar,</world>'
      expect(splitter.split_on_unquoted ',').to eq ['</hello>; <foo=bar', '</world>']
    end

    it 'ignores single quotes' do
      @string = "</hello> title=';' rel=next"
      expect(splitter.split_on_unquoted ';').to eq ["</hello> title='", "' rel=next"]
    end

    it 'treats inner quotes preceeded by a backslash literally' do
      # #@bs = \
      @string = %Q{</hello> title="#@bs";" rel}
      expect(splitter.split_on_unquoted ';').to eq [@string]
    end

    it 'treats a double backslash as a literal backslash (not an escape char)' do
      @string = %Q{</hello> title="#@bs#@bs";" rel}
      expect(splitter.split_on_unquoted ';').to eq [%Q{</hello> title="#@bs#@bs"}, '" rel']
    end

    it 'ignores leading backslashes (before opening quote)' do
      @string = %Q{</hello> title=#@bs";"; rel}
      expect(splitter.split_on_unquoted ';').to eq [%Q{</hello> title=#@bs";"}, ' rel']
    end

    it 'adds an empty string on trailing separators' do
      @string = '</hello>; crossorigin;'
      expect(splitter.split_on_unquoted ';').to eq ['</hello>', ' crossorigin', '']
    end

    it 'raises an error for non-string types' do
      @string = 123
      expect { splitter }.to raise_error TypeError
    end

  end
end