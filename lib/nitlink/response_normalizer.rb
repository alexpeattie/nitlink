require 'uri'
require_relative './hash_with_indifferent_access'

module Nitlink
  class ResponseNormalizer
    def metadata(response)
      response_class = response.class.name

      uri, status, (link, content_location) = case response_class
      when 'Curl::Easy'
        [response.url.chomp('?'), response.response_code, grab_headers(headers_from_string response.header_str)]
      when 'Excon::Response'
        scheme = response.port == 443 ? 'https' : 'http'
        # We have to reconstruct to URL annoyingly
        uri = URI::HTTP.new(scheme, nil, response.host, nil, nil, response.path, nil, nil, nil)

        [uri, response.status, grab_headers(response.headers)]
      when 'Faraday::Response'
        response = response.to_hash
        [response[:url], response[:status], grab_headers(response[:response_headers])]
      when 'HTTP::Message'
        [response.header.request_uri, response.status, grab_headers(Hash[response.header.all])]
      when 'HTTP::Response'
        [response.uri, response.status, grab_headers(response.headers.to_h)]
      when 'HTTParty::Response'
        [response.request.uri, response.code, grab_headers(response.response.to_hash)]
      when 'Patron::Response'
        [response.url, response.status, grab_headers(response.headers)]
      when 'RestClient::Response'
        [response.request.url, response.code, grab_headers(response.net_http_res.to_hash)]
      when 'Tempfile', 'StringIO'
        # ↑ returned by OpenURI
        [response.base_uri, response.status[0], grab_headers(response.meta)]
      when 'Typhoeus::Response'
        [response.request.base_url, response.code, grab_headers(response.headers)]
      when 'Unirest::HttpResponse'
        warn "Unirest support is deprecated and will be removed in Nitlink 2.0"
        return metadata(response.raw_body)
      when 'Hash'
        response = Nitlink::HashWithIndifferentAccess.new(response)
        response[:headers] = headers_from_string(response[:headers]) if String === response[:headers]

        [response[:request_uri], response[:status], grab_headers(response[:headers])]
      else
        if defined?(Net::HTTPResponse) && Net::HTTPResponse === response
          [response.uri, response.code, grab_headers(response.to_hash)]
        else
          raise unknown_type(response)
        end
      end

      [URI.parse(uri.to_s), (status ? Integer(status) : status), link, content_location]
    end

    private

    def headers_from_string(header_str)
      headers = header_str.split("\n").map do |header|
        header.strip.split(/\s*:\s*/, 2)
      end

      Hash[headers.reject(&:empty?)]
    end

    def grab_headers(headers)
      normalized_headers = Hash[headers.map { |key, value| [key.to_s.downcase, Array(value).join(',')] }]
      [normalized_headers['link'], normalized_headers['content-location']]
    end

    def unknown_type(response)
      UnknownResponseTypeError.new("Unknown response type #{response.class.name}")
    end
  end
end