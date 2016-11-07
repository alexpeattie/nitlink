require 'cgi'

module Nitlink
  class ParamDecoder
    def decode(param_value)
      charset, language, value_chars = param_value.split("'")

      raise syntax_error(param_value) unless charset && language && value_chars
      raise wrong_charset(charset) unless charset.downcase == 'utf-8'

      CGI.unescape(value_chars)
    end

    private

    def syntax_error(val)
      EncodedParamSyntaxError.new(%Q{Syntax error decoding encoded parameter value "#{ val }", must be in the form: charset "'" [ language ] "'" value-chars})
    end

    def wrong_charset(charset)
      UnsupportedCharsetError.new("Invalid charset #{charset}, encoded parameter values must use the UTF-8 character encoding") 
    end
  end
end