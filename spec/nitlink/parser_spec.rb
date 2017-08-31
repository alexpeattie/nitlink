# encoding: utf-8

require 'spec_helper'
require 'nitlink/parser'

RSpec.describe Nitlink::Parser do
  before {
    @options = {}
    @link = '</TheBook/chapter2>;rel="previous"'
  }
  let(:response) { { request_uri: 'http://example.com', status: 200, headers: { 'Link' => @link } } }
  let(:parser) { described_class.new }
  let(:first_link) { parser.parse(response).first }

  describe '#parse' do
    context 'link with no rel' do
      it 'returns an empty collection' do
        @link = '</hello>'
        expect(parser.parse response).to eq []
      end
    end

    context 'single link with single relation type' do
      before { @link = '</TheBook/chapter2>;rel="previous"' }

      it 'returns a single link object' do
        expect(parser.parse(response).size).to eq 1
      end

      it 'resolves a relative target' do
        expect(first_link.target.to_s).to eq 'http://example.com/TheBook/chapter2'
      end

      it 'keeps an absolute target' do
        @link = '<http://example.org/>; rel=duplicate'
        expect(first_link.target.to_s).to eq 'http://example.org/'
      end

      it 'sets the context to the request URI' do
        expect(first_link.context.to_s).to eq 'http://example.com'
      end
    end

    context 'single link with multiple relation types' do
      before { @link = '<http://example.org/>; rel="start http://example.net/relation/other"' }

      it 'creates one link object per relation type' do
        expect(parser.parse(response).size).to eq 2
      end

      it 'sets the corresponding relation types' do
        expect(parser.parse(response).map(&:relation_type)).to eq %w(start http://example.net/relation/other)
      end
    end

    context 'multiple links' do
      before { @link = '</TheBook/chapter2>;rel="previous", <http://example.org/>; rel="start http://example.net/relation/other"' }

      it 'creates a link object for every link and relation type' do
        expect(parser.parse(response).size).to eq 3
      end
    end

    context 'duplicate relation types' do
      before { @link = '</TheBook/chapter3>;rel="next", </TheBook/chapter4>;rel="next"' }

      it 'adds both links to the collection' do
        expect(parser.parse(response).size).to eq 2
      end
    end

    context 'malformed link' do
      it 'throws an error' do
        @link = '>/TheBook/chapter2<;rel="previous"'
        expect { parser.parse(response) }.to raise_error Nitlink::MalformedLinkHeaderError
      end
    end

    context 'incomplete responses' do
      it 'parses a response without Link headers (returns an empty LinkCollection)' do
        response[:headers] = {}
        expect(parser.parse(response)).to be_empty
      end

      it 'parses a response without a status code (assumes an anonymous context)' do
        response.delete(:status)
        expect(first_link.context).to be_nil
      end

      it 'can parse a response without a request URI, if the target is absolute' do
        @link = '<http://example.org/>; rel=next'

        response.delete(:request_uri)
        expect(first_link.target.to_s).to eq 'http://example.org/'
      end

      it "can't parse a response without a request URI, if the target is relative" do
        response.delete(:request_uri)
        expect { parser.parse(response) }.to raise_error URI::BadURIError
      end
    end

    it 'can capture arbitrary attributes in target_attributes' do
      @link = '<http://example.com/TheBook/chapter2>; rel="previous"; title="previous chapter"'
      expect(first_link.target_attributes['title']).to eq "previous chapter"
    end

    it "doesn't include rel or anchor in target_attributes" do
      @link = '<http://example.com/TheBook/chapter2>; rel="previous"; title="previous chapter"'
      expect(first_link.target_attributes.keys).to eq %w(title)
    end

    it 'parses an empty URI' do
      @link = '<>; rel="up"'
      expect(first_link.target.to_s).to eq 'http://example.com'
    end

    it "parses folded headers (even thought they're deprecated)" do
      @link = %Q{<http://example.com/TheBook/chapter2>;\r\n rel="previous"}
      expect(first_link.relation_type).to eq 'previous'
    end

    it 'decodes encoded parameter values (per RFC 5987)' do
      @link = "</TheBook/chapter2>; rel=next; title*=UTF-8''%c2%a3%20and%20%e2%82%ac%20rates"
      expect(first_link.target_attributes['title*']).to eq '£ and € rates'
    end

    it 'skips parameters that fail decoding' do
      @link = "</TheBook/chapter2>; rel=next; title*=UTF-9''%c2%a3%20and%20%e2%82%ac%20rates"
      expect(first_link.target_attributes.key?('title*')).to eq false
    end

    it 'ignores subsquent occurences of parameters that should appear once (like title)' do
      @link = '<http://example.com/TheBook/chapter2>; rel="previous"; title="title1"; title="title2"'
      expect(first_link.target_attributes['title']).to eq 'title1'
    end

    it 'replaces the context with an absolute anchor parameter' do
      @link = '</TheBook/chapter2>; rel=up; anchor="http://example.org/"'
      expect(first_link.context.to_s).to eq 'http://example.org/'
    end

    it 'relatively resolves a relative anchor parameter and uses it for context' do
      @link = '</TheBook/chapter2>; rel=up; anchor="foo#bar"'
      expect(first_link.context.to_s).to eq 'http://example.com/foo#bar'
    end

    it 'skips additional anchor or rel parameters' do
      @link = '</TheBook/chapter2>; rel=up; anchor="foo"; rel=down; anchor="bar"'
      expect(parser.parse(response).size).to eq 1

      expect(first_link.relation_type).to eq 'up'
      expect(first_link.context.to_s).to eq 'http://example.com/foo'
    end

    it 'uses the for context Content-Location if present & the request URI cannot be used' do
      redirected_response = { request_uri: 'http://example.com/redirect', status: 302, headers: { 'Link' => @link, 'Content-Location' => '/new' } }

      expect(parser.parse(redirected_response).first.context.to_s).to eq 'http://example.com/new'
    end

    it "sets context to nil (anonymous) where context can't be established (e.g. POST request)" do
      expect(parser.parse(response, 'POST').first.context).to eq nil
    end
  end
end