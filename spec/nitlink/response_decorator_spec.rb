require 'spec_helper'
%w(httparty faraday net/http http excon open-uri rest-client curb typhoeus httpclient patron).each do |lib|
  begin
    require lib
  rescue LoadError
    warn "skipping #{lib}"
  end
end
require 'nitlink/response'

RSpec.describe Nitlink::ResponseDecorator do
  let(:uri) { 'http://mockbin.org/bin/6fd230d4-c65a-48cb-a823-0594b05097ae' }
  let(:expected_target) { 'http://mockbin.org/view' }

  def about_link(response)
    response.links.by_rel('about').target.to_s
  end

  describe "decorating popular HTTP client libraries' responses with a new #links method" do
    it 'can decorate a Curb response' do
      expect(about_link Curl.get(uri)).to eq expected_target
    end

    it 'can decorate a Excon response' do
      expect(about_link Excon.get(uri)).to eq expected_target
    end

    it 'can decorate a Faraday response' do
      expect(about_link Faraday.get(uri)).to eq expected_target
    end

    it 'can decorate a http.rb response' do
      expect(about_link ::HTTP.get(uri)).to eq expected_target
    end

    it 'can decorate a HTTPClient response' do
      expect(about_link HTTPClient.new.get(uri)).to eq expected_target
    end

    it 'can decorate a HTTParty response' do
      expect(about_link HTTParty.get(uri)).to eq expected_target
    end

    it 'can decorate a Net::HTTP response' do
      expect(about_link Net::HTTP.get_response(URI.parse uri)).to eq expected_target
    end

    it 'can decorate a Patron response' do
      sess = Patron::Session.new
      expect(about_link sess.get(uri)).to eq expected_target
    end

    it 'can decorate a REST Client response' do
      expect(about_link RestClient.get(uri)).to eq expected_target
    end

    it 'can decorate a Typhoeus response' do
      expect(about_link Typhoeus.get(uri)).to eq expected_target
    end

    xit 'can decorate a Unirest response' do
      # This works, but the dependencies are out of date and cause conflicts
      expect(about_link Unirest.get(uri)).to eq expected_target
    end
  end
end