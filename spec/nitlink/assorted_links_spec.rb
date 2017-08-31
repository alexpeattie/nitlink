# encoding: utf-8

require 'spec_helper'
require 'nitlink/parser'

RSpec.describe 'assorted test cases for various Link headers (including edge cases)' do
  let(:parser) { Nitlink::Parser.new }
  let(:response) { { request_uri: 'http://example.com/', status: 200, headers: { 'Link' => @link } } }
  let(:parsed) { parser.parse(response) }

  describe 'test cases adapted from greenbytes' do
    # https://greenbytes.de/tech/tc/httplink/

    it 'parses a simple link' do
      @link = '<simple.css>; rel=stylesheet'
      expect(parsed.by_rel('stylesheet').target.to_s).to eq 'http://example.com/simple.css'
    end

    it 'rejects a simple link reversed' do
      @link = 'rel=stylesheet; <fail.css>'
      expect { parsed }.to raise_error Nitlink::MalformedLinkHeaderError
    end

    xit 'rejects a simple link relation name in single quotes' do
      @link = "<fail.css>; rel='stylesheet'"
      expect { parsed }.to raise_error Nitlink::MalformedLinkHeaderError
    end

    it 'parses a link with two relation types' do
      @link = '<simple.css>; rel="foobar stylesheet"'
      expect(parsed.by_rel('stylesheet').target.to_s).to eq 'http://example.com/simple.css'
      expect(parsed.by_rel('foobar').target.to_s).to eq 'http://example.com/simple.css'
    end

    it 'parses one link followed by another' do
      @link = '<foo>; rel=bar, <simple.css>; rel=stylesheet'
      expect(parsed.by_rel('bar').target.to_s).to eq 'http://example.com/foo'
      expect(parsed.by_rel('stylesheet').target.to_s).to eq 'http://example.com/simple.css'
    end

    it 'parses a link with an anchor' do
      @link = '<simple.css>; anchor="http://example.org/"; rel=stylesheet'
      expect(parsed.by_rel('stylesheet').context.to_s).to eq 'http://example.org/'
    end

    it 'parses a link with a blank anchor (identifying the current document)' do
      @link = '<simple.css>; anchor=""; rel=stylesheet'
      expect(parsed.by_rel('stylesheet').context.to_s).to eq 'http://example.com/'
    end

    it 'parses a link with a fragment for the anchor' do
      @link = '<simple.css>; anchor="#foo"; rel=stylesheet'
      expect(parsed.by_rel('stylesheet').context.to_s).to eq 'http://example.com/#foo'
    end

    it 'parses a link with a title' do
      @link = '<simple.css>; rel=stylesheet; title="A simple CSS stylesheet"'
      expect(parsed.by_rel('stylesheet').target_attributes['title']).to eq 'A simple CSS stylesheet'
    end

    it 'parses a link with a title containing escaped quotes/backslashes' do
      @link = '<simple.css>; rel=stylesheet; title="title with a DQUOTE \" and backslash: \\"'
      expect(parsed.by_rel('stylesheet').target_attributes['title']).to eq 'title with a DQUOTE " and backslash: \ '.strip
    end

    xit 'rejects a link with an unquoted title' do
      @link = '<simple.css>; rel=stylesheet; title=AsimpleCSSstylesheet'
      expect { parsed }.to raise_error ArgumentError
    end

    it 'parses a link with an RFC 5987 encoded title' do
      @link = "<simple.css>; rel=stylesheet; title*=UTF-8''stylesheet-%E2%82%AC"
      expect(parsed.by_rel('stylesheet').target_attributes['title*']).to eq 'stylesheet-€'
    end

    xit 'falls back to the title where title* cannot be decoded (invalid encoding)' do
    end

    it 'parses a link with an extension parameter' do
      @link = '<simple.css>; ext=foo; rel=stylesheet'
      expect(parsed.by_rel('stylesheet').target_attributes['ext']).to eq 'foo'
    end

    it 'parses a link with a boolean extension parameter' do
      @link = '<simple.css>; ext; rel=stylesheet'
      expect(parsed.by_rel('stylesheet').target_attributes['ext']).to eq nil
    end

    it 'parses a link with a quoted extension parameter' do
      @link = '<simple.css>; ext="\""; rel=stylesheet'
      expect(parsed.by_rel('stylesheet').target_attributes['ext']).to eq '"'
    end

    it 'parses a link with an extension relation type' do
      @link = '<simple.css>; rel="http://example.com/myrel stylesheet"'
      expect(parsed.by_rel('stylesheet').target.to_s).to eq 'http://example.com/simple.css'
      expect(parsed.by_rel('http://example.com/myrel').target.to_s).to eq 'http://example.com/simple.css'
    end
  end

  it 'parses links with seperators in the URL correctly' do
    @link = '</api/users/123?filter=my;ids=1,2,3>; rel="next"'
    expect(parsed.by_rel('next').target.to_s).to eq 'http://example.com/api/users/123?filter=my;ids=1,2,3'
  end

  it 'parses weird whitespace all over the place' do
    @link = "\n\t   <http://example.com>;rel=\t\"example\";   \ttitle =\"example dot com\" \n " 
    expect(parsed.by_rel('example').target.to_s).to eq 'http://example.com'
    expect(parsed.by_rel('example').target_attributes['title']).to eq 'example dot com'
  end

  it 'parses links with commas and semicolons in parameters' do
    @link = '<example.com>; rel=next; title="example; the second", <example-01.com>; rel=previous; title="alternate, version"'
    expect(parsed.by_rel('next').target_attributes['title']).to eq 'example; the second'
    expect(parsed.by_rel('previous').target_attributes['title']).to eq 'alternate, version'
  end

  it 'parses a real life Link header (from LetsEncrypt)' do
    @link = '<https://acme-staging.api.letsencrypt.org/acme/new-authz>;rel="next", <https://letsencrypt.org/documents/LE-SA-v1.1.1-August-1-2016.pdf>;rel="terms-of-service"'
    expect(parsed.by_rel('next').target.to_s).to eq 'https://acme-staging.api.letsencrypt.org/acme/new-authz'
    expect(parsed.by_rel('terms-of-service').target.to_s).to eq 'https://letsencrypt.org/documents/LE-SA-v1.1.1-August-1-2016.pdf'
  end

  it 'parses a URL without a scheme' do
    @link = '<//www.w3.org/wiki/LinkHeader>; rel="original latest-version"'
    expect(parsed.by_rel('original').target.to_s).to eq 'http://www.w3.org/wiki/LinkHeader'
  end

  it 'parses crazy looking but valid link headers' do
    # Credit: https://github.com/fuzzyBSc/weblinking/blob/master/test/test.js
    @link = <<'EOS'
    <http://example.com/;;;,,,>; rel="next;;;,,, next"; a-zA-Z0-9!#$&+-.^_`|~=!#$%&'()*+-./0-9:<=>?@a-zA-Z[]^_`{|}~; title*=UTF-8'de'N%c3%a4chstes%20Kapitel
EOS

    expect(parsed.by_rel('next').target_attributes['a-za-z0-9!#$&+-.^_`|~']).to eq "!#$%&'()*+-./0-9:<=>?@a-zA-Z[]^_`{|}~"
    expect(parsed.by_rel('next;;;,,,').target.to_s).to eq 'http://example.com/;;;,,,'
  end

end