require_relative '../nitlink'

module Nitlink
  module ResponseDecorator
    def links
      Nitlink::Parser.new.parse(self)
    end
  end
end

third_party_clients = ['Curl::Easy', 'Excon::Response', 'Faraday::Response', 'HTTP::Message', 'HTTP::Response', 'HTTParty::Response', 'Net::HTTPResponse', 'Patron::Response', 'RestClient::Response', 'Typhoeus::Response', 'Unirest::HttpResponse']

decoratable_responses = third_party_clients.select do |klass|
  module_name, class_name = klass.split('::', 2)
  Object.const_defined?(module_name) && Object.const_get(module_name).const_defined?(class_name)
end

decoratable_responses.each do |klass|
  module_name, class_name = klass.split('::', 2)
  Object.const_get(module_name).const_get(class_name).class_eval { include Nitlink::ResponseDecorator }
end