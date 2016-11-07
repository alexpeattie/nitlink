require_relative '../nitlink'

module Nitlink
  module ResponseDecorator
    def links
      Nitlink::Parser.new.parse(self)
    end
  end
end

decoratable_responses = ['Curl::Easy', 'Excon::Response', 'Faraday::Response', 'HTTP::Message', 'HTTP::Response', 'HTTParty::Response', 'Net::HTTPResponse', 'Patron::Response', 'RestClient::Response', 'Typhoeus::Response', 'Unirest::HttpResponse']
decoratable_responses.select { |klass| Object.const_defined?(klass) }.each do |klass|
  Object.const_get(klass).class_eval { include Nitlink::ResponseDecorator }
end