require 'spec_helper'
%w(httparty faraday net/http http excon open-uri rest-client curb typhoeus httpclient patron).each do |lib|
  begin
    require lib
  rescue LoadError
    warn "skipping #{lib}"
  end
end

RSpec.describe Nitlink::ResponseNormalizer do
  let(:rn) { described_class.new }
  let(:uri) { 'http://mockbin.org/bin/e8fa7afc-26b6-4ccf-a00c-ebaac4d11461' }
  let(:expected_metadata) { [ URI.parse(uri), 200, '</view>; rel=about', 'http://example.com'] }
  let(:headers) { { 'Content-Location' => 'http://example.com', 'Link' => '</view>; rel=about' } }

  describe 'normalizing data provided as a hash' do
    it 'parses headers provided as a hash' do
      expect(rn.metadata(status: 200, request_uri: uri, headers: {
        'Content-Location' => 'http://example.com',
        'link' => '</view>; rel=about'
      })).to eq expected_metadata
    end

    it 'allows keys to be strings or symbols' do
      expect(rn.metadata(status: 200, "request_uri" => uri, headers: {
        'Content-Location' => 'http://example.com',
        link: '</view>; rel=about'
      })).to eq expected_metadata 
    end

    it 'parses string headers' do
      headers_str = "
      Content-Location: http://example.com
      Content-Type:text/html; charset=UTF-8

      link: </view>; rel=about
      "

      expect(rn.metadata(status: 200, request_uri: uri, headers: headers_str)).to eq expected_metadata
    end

    it 'returns request URI as instance of URI::HTTP' do
      expect(rn.metadata(status: 200, request_uri: uri, headers: headers).first).to be_a URI::HTTP
      expect(rn.metadata(status: 200, request_uri: URI.parse(uri), headers: headers).first).to be_a URI::HTTP
    end

    it 'converts status to an integer (if neccessary)' do
      expect(rn.metadata(status: '200', request_uri: uri, headers: headers)[1]).to eq 200
    end

    it 'raises an error where status is non-numeric' do 
      expect { rn.metadata(status: 'OK', request_uri: uri, headers: headers) }.to raise_error ArgumentError
    end

    it 'combines multiple Link headers (e.g. an array) into a single Link header (joining with commas)' do
      _uri, _status, link, _context = rn.metadata(status: 200, request_uri: uri, headers: {
        'Content-Location' => 'http://example.com',
        'Link' => ['</view>; rel=about', '</page2>; rel=next']
      })

      expect(link).to eq '</view>; rel=about,</page2>; rel=next'
    end

    it 'raises an error when the response is of an unhandled type' do
      UnkResponse = Struct.new(:foo)
      expect { rn.metadata(UnkResponse.new('bar')) }.to raise_error Nitlink::UnknownResponseTypeError
    end
  end

  describe 'parsing responses from popular HTTP client libraries' do
    it 'can process a Curb response' do
      expect(rn.metadata Curl.get(uri)).to eq expected_metadata
    end

    it 'can process a Excon response' do
      expect(rn.metadata Excon.get(uri)).to eq expected_metadata
    end

    it 'can process a Faraday response' do
      expect(rn.metadata Faraday.get(uri)).to eq expected_metadata
    end

    it 'can process a http.rb response' do
      expect(rn.metadata ::HTTP.get(uri)).to eq expected_metadata
    end

    it 'can process a HTTPClient response' do
      expect(rn.metadata HTTPClient.new.get(uri)).to eq expected_metadata
    end

    it 'can process a HTTParty response' do
      expect(rn.metadata HTTParty.get(uri)).to eq expected_metadata
    end

    it 'can process a Net::HTTP response' do
      expect(rn.metadata Net::HTTP.get_response(URI.parse uri)).to eq expected_metadata
    end

    it 'can process an OpenURI response' do
      expect(rn.metadata open(uri)).to eq expected_metadata
    end

    it 'can process a Patron response' do
      sess = Patron::Session.new
      expect(rn.metadata sess.get(uri)).to eq expected_metadata
    end

    it 'can process a REST Client response' do
      expect(rn.metadata RestClient.get(uri)).to eq expected_metadata
    end

    it 'can process a Typhoeus response' do
      expect(rn.metadata Typhoeus.get(uri)).to eq expected_metadata
    end

    it 'can process a Unirest response, but gives a deprecation warning' do
      response = instance_double('Unirest::HttpResponse')
      allow(response).to receive_message_chain(:class, :name => 'Unirest::HttpResponse')
      allow(response).to receive(:raw_body).and_return(Net::HTTP.get_response(URI.parse uri))

      expect(rn.metadata response).to eq expected_metadata
      expect { rn.metadata response }.to output.to_stderr
    end
  end
end