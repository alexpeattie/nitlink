source 'https://rubygems.org'

gemspec
gem 'simplecov-shield', git: 'https://github.com/aterris/simplecov-shield'

group :clients do
  if RUBY_VERSION == '1.9.3'
    gem 'httparty', '0.14.0'
    gem 'mime-types', '2.6.2'
    gem 'http', '1.0.4'
    gem 'rest-client', '1.8.0'
  else
    gem 'httparty', '>= 0.14.0'
    gem 'http', '>= 2.0.0'
    gem 'rest-client', '>= 2.0.2'
  end
  gem 'faraday', '>= 0.9.2'
  gem 'excon', '>= 0.45.4'
  gem 'curb', '>= 0.9.3'
  gem 'typhoeus', '>= 1.1.0'
  gem 'httpclient', '>= 2.8'
  gem 'patron', '>= 0.8.0'
  # gem 'unirest', '>= 1.1.2'
end
