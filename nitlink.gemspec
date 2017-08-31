# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'nitlink/version'

Gem::Specification.new do |spec|
  spec.name          = 'nitlink'
  spec.version       = Nitlink::VERSION
  spec.authors       = ['Alex Peattie']
  spec.email         = ['me@alexpeattie.com']

  spec.summary       = 'Nitlink is a nitpicky gem for parsing Link headers (per RFC 5988)'
  spec.description   = 'Nitlink is a nice, nitpicky gem for parsing Link headers, which aims to stick
 as closely as possible to RFC 5988. Has support for UTF-8 encoded parameters, URI resolution, boolean parameters,
 weird edge cases and more.'
  spec.homepage      = 'https://github.com/alexpeattie/nitlink'
  spec.license       = 'MIT'

  spec.files         = Dir['{lib,spec}/**/*.rb'] + %w(LICENSE README.md)
  spec.require_paths = ['lib']
  spec.files         = Dir['lib/**/*.rb']

  spec.required_ruby_version = '>= 1.9.3'

  spec.add_development_dependency 'bundler', '>= 1.7.6'
  spec.add_development_dependency 'rake', '~> 10.0'
  spec.add_development_dependency 'rspec', '~> 3.5.0'
  spec.add_development_dependency 'simplecov', '~> 0.12.0'
  spec.add_development_dependency 'simplecov-shield', '~> 0.1.0'
  spec.add_development_dependency 'addressable', '~> 2.4.0'
end
