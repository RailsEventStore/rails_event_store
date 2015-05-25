# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'ruby_event_store/version'

Gem::Specification.new do |spec|
  spec.name          = "ruby_event_store"
  spec.version       = RubyEventStore::VERSION
  spec.authors       = ["rybex"]
  spec.email         = ["tomek.rybka@gmail.com"]

  spec.summary       = %q{Implementation of Event Store in Ruby}
  spec.description   = %q{Implementation of Event Store in Ruby}
  spec.homepage      = ''

  spec.files         = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.8"
  spec.add_development_dependency "rake", "~> 10.0"
  spec.add_development_dependency 'rspec'
  spec.add_development_dependency 'pry'
  spec.add_development_dependency 'mutant', '~> 0.7.8'
  spec.add_development_dependency 'mutant-rspec', '~> 0.7.8'
end
