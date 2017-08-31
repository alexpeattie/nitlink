require_relative './exceptions'
require_relative './splitter'
require_relative './link_collection'
require_relative './link'
require_relative './response_normalizer'
require_relative './param_extractor'
require_relative './param_decoder'

module Nitlink
  class Parser
    SINGLE_LINK = /\A\s*<([^>]*)>(.*)/
    RWS = /[\x09\x20]+/

    attr_reader :options

    def parse(response, http_method = 'GET')
      @http_method = http_method
      @request_uri, @status, link_header, @content_location_header = ResponseNormalizer.new.metadata(response)

      links = LinkCollection.new
      return links unless link_header

      unfolded_header = link_header.gsub(/\r?\n[\x20\x09]+/, '')
      link_strings = Splitter.new(unfolded_header).split_on_unquoted(',')

      parse_links(link_strings, links)
    end

    private

    def parse_links(link_strings, link_collection)
      link_strings.each do |link_string|
        well_formed, target_string, rest = link_string.match(SINGLE_LINK).to_a
        raise malformed(link_string) unless well_formed

        link_parameters = ParamExtractor.new.extract(rest)
        create_links(target_string, link_parameters).each { |link| link_collection.push(link) }
      end

      link_collection
    end

    def create_links(target_string, link_parameters)
      target, relation_types, context, target_attributes = link_attributes(target_string, link_parameters)
      relation_types.map do |relation_type|
        Link.new(target, relation_type, context, target_attributes)
      end
    end

    def link_attributes(target_string, link_parameters)
      target = @request_uri.merge(target_string)

      relations_string = first_match(link_parameters, 'rel') || ''
      relation_types = relations_string.split(RWS)

      context_string = first_match(link_parameters, 'anchor') || identity
      context = (context_string && @request_uri.scheme) ? @request_uri.merge(context_string) : nil

      target_attributes = extract_target_attributes(link_parameters)
      [target, relation_types, context, target_attributes]
    end

    def first_match(link_parameters, param_name)
      (link_parameters.find { |name, _value| name == param_name } || []).last
    end

    def extract_target_attributes(link_parameters)
      target_attributes = []
      link_parameters.each do |param_name, param_value|
        next if %(rel anchor).include?(param_name)
        next if %(media title title* type).include?(param_name) && first_match(target_attributes, param_name)

        begin
          param_value = decode(param_value) if param_name.end_with?('*')
        rescue EncodedParamSyntaxError, UnsupportedCharsetError
          next
        end

        target_attributes.push [param_name, param_value]
      end

      Hash[target_attributes]
    end

    def malformed(link_string)
      MalformedLinkHeaderError.new("Malformed link header (#{ link_string })")
    end

    def decode(param_value)
      ParamDecoder.new.decode(param_value)
    end

    def identity
      if %w(GET HEAD).include?(@http_method.upcase) && [200, 203, 204, 206, 304].include?(@status)
        @request_uri
      else
        @content_location_header
      end
    end
  end
end