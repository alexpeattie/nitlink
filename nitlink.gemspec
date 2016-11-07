# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'nitlink/version'

Gem::Specification.new do |spec|
  spec.name          = 'nitlink'
  spec.version       = Nitlink::VERSION
  spec.authors       = ['Alex Peattie']
  spec.email         = ['me@alexpeattie.com']

  spec.summary       = %q{Write a short summary, because Rubygems requires one.}
  spec.description   = %q{Write a longer description or delete this line.}
  spec.homepage      = 'https://github.com/alexpeattie/nitlink'
  spec.license       = 'MIT'

  spec.files         = `git ls-files -z`.split("\x0").reject do |f|
    f.match(%r{^(test|spec|features)/})
  end
  spec.require_paths = ['lib']

  spec.add_dependency 'hashwithindifferentaccess', '~> 0.1.1'

  spec.add_development_dependency 'bundler', '~> 1.13'
  spec.add_development_dependency 'rake', '~> 10.0'
  spec.add_development_dependency 'rspec', '~> 3.5.0'
  spec.add_development_dependency 'simplecov', '~> 0.12.0'
  spec.add_development_dependency 'simplecov-shield', '~> 0.1.0'
end
