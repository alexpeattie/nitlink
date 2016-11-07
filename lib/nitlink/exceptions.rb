module Nitlink
  class MalformedLinkHeaderError < StandardError; end
  class EncodedParamSyntaxError < StandardError; end
  class UnsupportedCharsetError < StandardError; end
  class UnknownResponseTypeError < StandardError; end
end