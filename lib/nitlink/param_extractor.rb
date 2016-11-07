module Nitlink
  class ParamExtractor
    QUOTED_VALUE = /\A"(.*)"\Z/m
    QUOTED_PAIR = /\\./m

    LEADING_OWS = /\A[\x09\x20]+/
    TRAILING_OWS = /[\x09\x20]+\Z/

    def extract(rest)
      @rest = rest
      parameter_strings = Splitter.new(rest).split_on_unquoted(';')
      raw_params = parameter_strings.map do |parameter_str|
        strip_ows(parameter_str).split('=', 2)
      end

      return format(raw_params)
    end

    private

    def format(raw_params)
      raw_params.map do |raw_param_name, raw_param_value|
        next if !raw_param_name
        param_name = rstrip_ows(raw_param_name.downcase)

        if raw_param_value
          param_value = lstrip_ows(raw_param_value)
          param_value = format_quoted_value(param_value) if quoted?(param_value)
        else
          param_value = nil
        end

        [param_name, param_value]
      end.compact
    end

    def format_quoted_value(quoted_value)
      without_quotes = quoted_value.strip[QUOTED_VALUE, 1]
      without_quotes.gsub(QUOTED_PAIR) { |match| match.chars.to_a.last }
    end

    def quoted?(param_value)
      param_value =~ QUOTED_VALUE
    end

    def lstrip_ows(str)
      str.gsub(LEADING_OWS, '')
    end

    def rstrip_ows(str)
      str.gsub(TRAILING_OWS, '')
    end

    def strip_ows(str)
      rstrip_ows(lstrip_ows str)
    end
  end
end