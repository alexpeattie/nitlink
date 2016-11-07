# Nitlink :link:

![Coverage badge](https://cdn.rawgit.com/alexpeattie/nitlink/master/coverage/coverage.svg)

**Nitlink** is a nice, nitpicky gem for parsing Link headers, which sticks as closely as possible to Mark Nottingham's parsing algorithm (from his [most recent redraft of RFC 5988](https://mnot.github.io/I-D/rfc5988bis/?#parse)). Than means it's [particularly good](#feature-comparison) at handling weird edge cases, UTF-8 encoded parameters, URI resolution, boolean parameters and more. It also plays nicely with [a bunch](#third-party-clients) of popular HTTP client libraries, and has an extensive test suite.

Tested with Ruby versions from **1.9.3** up to **2.3.1**.

## Installation

Install the gem from RubyGems:

```bash
gem install nitlink
```

Or add it to your Gemfile and run `bundle install`

```ruby
gem 'nitlink', '~> 1.0'
```

And you're ready to go!

```ruby
require 'httparty'
require 'nitlink/response'

HTTParty.get('https://www.w3.org/wiki/Main_Page').links.by_rel('last').target
 => #<URI::HTTPS https://www.w3.org/wiki/index.php?title=Main_Page&oldid=100698>
```

## Usage

The most basic way to use Nitlink is to directly pass in a HTTP response from `Net::HTTP`:

```ruby
require 'nitlink'
require 'net/http'
require 'awesome_print' # <- not required, just for this demo

link_parser = Nitlink::Parser.new
response = Net::HTTP.get_response(URI.parse 'https://api.github.com/search/code?q=addClass+user:mozilla')

links = link_parser.parse(response)
ap links

# =>
[
    [0] #<Nitlink::Link:0x7fcd09019158
        context = #<URI::HTTPS https://api.github.com/search/code?q=addClass+user:mozilla>,
        relation_type = "next",
        target = #<URI::HTTPS https://api.github.com/search/code?q=addClass+user%3Amozilla&page=2>,
        target_attributes = {}
    >,
    [1] #<Nitlink::Link:0x7fcd09011fe8
        context = #<URI::HTTPS https://api.github.com/search/code?q=addClass+user:mozilla>,
        relation_type = "last",
        target = #<URI::HTTPS https://api.github.com/search/code?q=addClass+user%3Amozilla&page=34>,
        target_attributes = {}
    >
]
```

`links` is actually a `Nitlink::LinkCollection` - an enhanced array which makes it convenient to grab a link based on its `relation_type`:

```ruby
links.by_rel('next').target.to_s
#=> 'https://api.github.com/search/code?q=addClass+user%3Amozilla&page=2'
```

#### Third-party clients

Nitlink also supports a large number of third-party HTTP clients:

- [Curb](https://github.com/taf2/curb)
- [Excon](https://github.com/excon/excon)
- [Faraday](https://github.com/lostisland/faraday)
- [http.rb](https://github.com/httprb/http)
- [httpclient](https://github.com/nahi/httpclient)
- [HTTParty](https://github.com/jnunemaker/httparty)
- [OpenURI](https://ruby-doc.org/stdlib-2.3.1/libdoc/open-uri/rdoc/OpenURI.html) (part of the standard lib)
- [Patron](https://github.com/toland/patron)
- [REST Client](https://github.com/rest-client/rest-client)
- [Typhoeus](https://github.com/typhoeus/typhoeus)
- [Unirest](https://github.com/Mashape/unirest-ruby)

You can pass a HTTP response from one of these libraries straight into the `parse` method:

```ruby
response = HTTParty.get('https://api.github.com/search/code?q=addClass+user:mozilla')
links = link_parser.parse(response)
```
<br>
For the extra lazy, you can instead require `nitlink/response` which decorates the various response objects from third-party clients with a new `.links` method, which returns the parsed Link headers from that response. `nitlink/response` must be required **after** the third-party client. (Note: `Net::HTTPResponse` also gets decorated, even though it's not technically third-party).

```ruby
require 'httparty'
require 'nitlink/response'

ap HTTParty.get('https://api.github.com/search/code?q=addClass+user:mozilla').links

# =>
[
    [0] #<Nitlink::Link:0x7fcd09019158
        context = #<URI::HTTPS https://api.github.com/search/code?q=addClass+user:mozilla>,
# ....
```

`response.links` is just syntactic sugar for calling `Nitlink::Parser.new.parse(response)`

#### Response as a hash

You can also pass the relevant response data as a hash (with keys as strings or symbols):

```ruby
links = link_parser.parse({
  request_uri: 'https://api.github.com/search/code?q=addClass+user:mozilla',
  status: 200,
  headers: { 'Link' => '<https://api.github.com/search/code?q=addClass+user%3Amozilla&page=2>; rel="next", <https://api.github.com/search/code?q=addClass+user%3Amozilla&page=34>; rel="last"' }
})
```

#### Non-`GET` requests

For fully correct behavior, when the making a request using a HTTP method other than `GET`, specify the method type as the second argument of `parse`:

```ruby
response = HTTParty.post('https://api.github.com/search/code?q=addClass+user:mozilla')
links = link_parser.parse(response, 'POST')
```

This allows Nitlink to correctly set the `context` of links (resources fetched by a method other than `GET` or `HEAD` generally have an anonymous context) - but otherwise everything works OK if you don't specify this.

#### Example: paginating Github search

Here we make an initial call to the Github API's [search endpoint](https://developer.github.com/v3/search/#search-code) then iterate through the pages of results using Link headers:

```ruby
require 'nitlink'
require 'net/http'

link_parser = Nitlink::Parser.new
first_page = HTTParty.get('https://api.github.com/search/code?q=onwheel+user:mozilla')
links = link_parser.parse(first_page)

results = first_page.parsed_response['items']

while links.by_rel('next')
  response = HTTParty.get(links.by_rel('next').target)
  results += first_page.parsed_response['items']

  links = link_parser.parse(response)
end
```

## Feature comparison

A few different Link header parsers (in various languages) already exist. Some of them are quite lovely :relaxed: ! Nitlink does its best to be as feature complete as possible; as far as I know it's the first library to cover all the area the spec (RFC 5988) sets out:

| Feature | Nitlink | [parse-link-header](https://github.com/thlorenz/parse-link-header) | [link_header](https://github.com/asplake/link_header) | [li](https://github.com/jfromaniello/li) | [weblinking](https://github.com/fuzzyBSc/weblinking) | [link-headers](https://github.com/wombleton/link-headers) | [backbone-paginator](https://github.com/backbone-paginator/backbone.paginator) | [http-link](https://github.com/victorenator/http-link) | [node-http-link-header](https://github.com/jhermsmeier/node-http-link-header) |
| ------------- | ------------- | ------------- | ------------- | ------------- | ------------- |  ------------- | ------------- | ------------- | ------------- |
| Encoded params (per RFC 5987) | <p align='center'>:white_check_mark:</p> | <p align='center'>:x:</p> | <p align='center'>:x:</p> | <p align='center'>:x:</p> | <p align='center'>:white_check_mark:</p> | <p align='center'>:x:</p> | <p align='center'>:x:</p> | <p align='center'>:x:</p> | <p align='center'>:white_check_mark:</p> |
| URI resolution | <p align='center'>:white_check_mark:</p> | <p align='center'>:x:</p> | <p align='center'>:x:</p> | <p align='center'>:x:</p> | <p align='center'>:white_check_mark:</p> | <p align='center'>:x:</p> | <p align='center'>:x:</p> | <p align='center'>:x:</p> |<p align='center'>:x:</p> |
| Establish link context | <p align='center'>:white_check_mark:</p> | <p align='center'>:x:</p> | <p align='center'>:x:</p> | <p align='center'>:x:</p> | <p align='center'>:x:</p> | <p align='center'>:x:</p> | <p align='center'>:x:</p> | <p align='center'>:x:</p> | <p align='center'>:x:</p> |
| Ignore quoted separators | <p align='center'>:white_check_mark:</p> | <p align='center'>:x:</p> | <p align='center'>:white_check_mark:</p> | <p align='center'>:x:</p> | <p align='center'>:white_check_mark:</p> | <p align='center'>:white_check_mark:</p> | <p align='center'>:x:</p> | <p align='center'>:white_check_mark:</p> | <p align='center'>:white_check_mark:</p> |
| Parse "weird" headers<sup>†</sup> | <p align='center'>:white_check_mark:</p> | <p align='center'>:x:</p> | <p align='center'>:x:</p> | <p align='center'>:x:</p> | <p align='center'>:white_check_mark:</p> | <p align='center'>:x:</p> | <p align='center'>:x:</p> | <p align='center'>:x:</p> | <p align='center'>:x:</p> |
| Proper escaping | <p align='center'>:white_check_mark:</p> | <p align='center'>:x:</p> | <p align='center'>:white_check_mark:</p> | <p align='center'>:x:</p> | <p align='center'>:white_check_mark:</p> | <p align='center'>:white_check_mark:</p> | <p align='center'>:x:</p> | <p align='center'>:white_check_mark:</p> | <p align='center'>:x:</p> |
| Boolean attributes | <p align='center'>:white_check_mark:</p> | <p align='center'>:x:</p> | <p align='center'>:x:</p> | <p align='center'>:x:</p> | <p align='center'>:x:</p> | <p align='center'>:x:</p> | <p align='center'>:x:</p> | <p align='center'>:x:</p> | <p align='center'>:x:</p> |
| Ignore duplicate params | <p align='center'>:white_check_mark:</p> | <p align='center'>:x:</p> | <p align='center'>:x:</p> | <p align='center'>:x:</p> | <p align='center'>:x:</p> | <p align='center'>:x:</p> | <p align='center'>:x:</p> | <p align='center'>:x:</p> | <p align='center'>:x:</p> |
| Multiple relation types | <p align='center'>:white_check_mark:</p> | <p align='center'>:white_check_mark:</p> | <p align='center'>:x:</p> | <p align='center'>:x:</p> | <p align='center'>:x:</p> | <p align='center'>:white_check_mark:</p> | <p align='center'>:x:</p> | <p align='center'>:x:</p> | <p align='center'>:x:</p> |

<sup>†</sup> i.e. can it parse weird looking, but technically valid headers like `<http://example.com/;;;,,,>; rel="next;;;,,, next"; a-zA-Z0-9!#$&+-.^_|~=!#$%&'()*+-./0-9:<=>?@a-zA-Z[]^_{|}~; title*=UTF-8'de'N%c3%a4chstes%20Kapitel`?

## API

### Nitlink::Parser

#### `parse(response, method = 'GET')` => `Nitlink::LinkCollection`

Accepts the following arguments:

* `response` (required) - The HTTP response whose `Link` header you wish to parse. Can be any one of:
  * An instance of `Net::HTTPResponse` and its subclasses
  * An instance of `Curl::Easy`, `Excon::Response`, `Faraday::Response`, `HTTP::Message`, `HTTP::Response`, `HTTParty::Response`, `Patron::Response`, `RestClient::Response`, `Typhoeus::Response` or `Unirest::HttpResponse`
  * An instance of `StringIO` or `Tempfile` created by `OpenURI`'s `Kernel#open` method
  * A `Hash` containing:
    * `request_uri` (`String` or `URI`) - the URI of the requested resource
    * `status` - the numerical status code of the response (e.g. `200`)
    * `headers` (`Hash` or `String`) - headers can either be provided as a Hash of HTTP header fields (with keys being the field names and the values being the field values) or a raw HTTP header string (each field separated by CR-LF pairs). Only the `Link` and `Content-Location` headers are used by Nitlink. Nitlink treats field names case-insensitively.
    <br><br>

      ```ruby
      { headers: {
        'Content-Location' => 'http://example.com'
        'Link' => '</page/2>; rel=next'
      } }

      # Or

      { headers: "Content-Location: http://example.com\r\nLink: </page/2>; rel=next" }
      ```


* `method` (`String`, optional) - The HTTP method used to make the request. Defaults to `'GET'`. This is used to establish the correct identity (per [RFC 7231](https://www.rfc-editor.org/info/rfc7231), Section 3.1.4.1)

Returns a `Nitlink::LinkCollection` containing `Nitlink::Link` objects:

* When the response contains no `Link` header an empty collection is returned
* Links without a relation type (`rel`) specified are omitted
* The links' parameters are serialized into the `Nitlink::Link`'s `target_attributes`. For more details of the serialization see `Nitlink::Link#target_attributes` [below](#target_attributes--hash).
* Where a link has more than one relation type, one entry per relation type is appended:

  ```ruby
  ap parser.parse({
    request_uri: 'http://example.com',
    status: 200,
    headers: { 'Link' => '</readme>; rel="about version-history"' }
  })

  [
      [0] #<Nitlink::Link:0x7fcda9330be8
          context = #<URI::HTTP http://example.com>,
          relation_type = "about",
          target = #<URI::HTTP http://example.com/readme>,
          target_attributes = {}
      >,
      [1] #<Nitlink::Link:0x7fcda9330bc0
          context = #<URI::HTTP http://example.com>,
          relation_type = "version-history",
          target = #<URI::HTTP http://example.com/readme>,
          target_attributes = {}
      >
  ]
  ```

If the `Link` header does not begin with `"<"`, or `"<"` isn't followed by `">"` it's considered malformed and unparseable - in which case a **`Nitlink::MalformedLinkHeaderError`** is thrown. If `response` is an instance of a class which Nitlink doesn't know how to handle (e.g. from an unsupported third-party client) a **`Nitlink::UnknownResponseTypeError`** is thrown.

### Nitlink::LinkCollection

An extension of `Array` with additional convenience methods for handling links based on their relation type.

#### `by_rel(relation_type)` => `Nitlink::Link` or `nil`

Accepts the following argument:

* `relation_type` (required, `String` or `Symbol`) - a single relation type which the returned link should represent (e.g. `by_rel('terms-of-service')` would find a link pointing to legal terms).

Returns a single `Nitlink::Link` object whose `relation_type` attribute matches the relation type provided, or `nil` if the collection doesn't contain a matching link. If two links exist which match the provided relation type (this should never happen in practice), the first matching link in the collection is returned.

Raises an **`ArgumentError`** if the `relation_type` is blank.

#### `to_h` => `Hash`

Returns a [`HashWithIndifferentAccess`](http://api.rubyonrails.org/classes/ActiveSupport/HashWithIndifferentAccess.html) where each key is a relation type and each value is a `Nitlink::Link`. An empty collection will return an empty hash. If two links exist which match a given relation type, the value will be the first link in the collection.

### Nitlink::Link

A `Struct` representing a single link with a specific relation type. It has four attributes:

* `context` - the context of the link
* `target` - where the linked resource is located
* `relation_type` - the relation type, which identifies the semantics of the link
* `target_attributes` - a set of key/value pairs that give additional information about the link

```ruby
#<Nitlink::Link:0x7fcda89489a0
    context = #<URI::HTTP http://example.com>,
    target = #<URI::HTTP http://example.com/readme>,
    relation_type = "about",
    target_attributes = {
      "title" => "About us"
    }
>
```

#### `context` => `URI` or `nil`

Returns the context of the link as a `URI` object. Usually this will be the same as the request URI, but may be modified by the `anchor` parameter or `Content-Location` header. Additionally some HTTP request methods or status codes result in an "anonymous" link context being assigned (represented by `nil`).

#### `target` => `URI`

Returns the target of the link as a `URI` object. If the URI given in the `Link` header is relative, Nitlink resolves it (based on the request URI).

#### `relation_type` => `String`

A single relation type, describing the kind of relationship this link represents. For example, `"prev"` would indicate that the target resource immediately precedes the context. It could also be an extension relation type (an absolute URI serialized as a string).

Relation types are always case-normalized to lowercase.

#### `target_attributes` => `Hash`

Captures the values of the parameters that aren't used to construct the `context` or `target` (i.e. other than `rel` and `anchor`) `title`, for example.

Parameters ending in `*` are decoded per [RFC 5987, bis-03](https://tools.ietf.org/html/draft-ietf-httpbis-rfc5987bis-03). Where decoding fails, the parameter is omitted.

Boolean parameters (e.g. `crossorigin`) have their values set to `nil`. Any backslash escaped characters within quoted parameter values are unescaped. The names of attributes are case-normalized to lowercase. Only the first occurrences of `media`, `title`, `title*` or `type` parameters are parsed, subsequent occurrences are ignored.

If no additional parameters exist, `target_attributes` is an empty hash.

```ruby
ap parser.parse({
  request_uri: 'http://example.com',
  status: 200,
  headers: { 'Link' => %q{</about>; rel=about; title="About us"; title*=utf-8'en'About%20%C3%BCs; crossorigin} }
})

#=>
[
    [0] #<Nitlink::Link:0x7fcda9274bc8
        context = #<URI::HTTP http://example.com>,
        relation_type = "about",
        target = #<URI::HTTP http://example.com/about>,
        target_attributes = {
                  "title" => "About us",
                 "title*" => "About üs",
            "crossorigin" => nil
        }
    >
]
```

## Changelog

Nitlink follows [semantic versioning](http://semver.org/).

#### [1.0.0](https://rubygems.org/gems/nitlink/versions/1.0.0) (7 November 2016)

* Initial release

## Developing Nitlink

1. Clone the git repo

  ```
  git clone git://github.com/alexpeattie/nitlink.git
  ```

2. Install dependencies

  ```
  cd nitlink
  bundle install
  ```

  You can skip installing the various third-party HTTP clients Nitlink supports, to get up and running faster (some specs will fail)

  ```
  bundle install --without clients
  ```

3. Run the test suite

  ```
  bundle exec rspec
  ```

  You can also generate a [Simplecov](https://github.com/colszowka/simplecov) coverage report by setting the `COVERAGE` environment variable:

  ```
  COVERAGE=true bundle exec rspec
  ```

## Contributing

Pull requests are very welcome! Please try to follow these simple rules if applicable:

* Fork it (https://github.com/alexpeattie/nitlink/fork)
* Create your feature branch (`git checkout -b my-new-feature`)
* Commit your changes (`git commit -am 'Add some feature'`)
* Push to the branch (`git push origin my-new-feature`)
* Create a new Pull Request

## Future features

* Validate (non-extension) relation types against those listed in the official [Link Relation Type Registry](http://www.iana.org/assignments/link-relations/link-relations.xhtml)
* Check the format of known parameters (e.g. `type` should be in the format `foo/bar`)
* Detect the language of the linked resource (from `hreflang` or language information in an encoded `title*`)
* Convert extension relation types to `URI`s
* Support for [parameter fallback](https://mnot.github.io/I-D/rfc5988bis/?#rfc.section.6.4.2)
* Add option to ignore links with anchor parameters
* Better handling of duplicate parameters

## License

Nitlink is released under the MIT license. (See [License.md](./License.md))

## Author

Alex Peattie / [alexpeattie.com](https://alexpeattie.com/) / [@alexpeattie](https://twitter.com/alexpeattie) 
