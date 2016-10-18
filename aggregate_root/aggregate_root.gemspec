# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'aggregate_root/version'

Gem::Specification.new do |spec|
  spec.name          = 'aggregate_root'
  spec.version       = AggregateRoot::VERSION
  spec.licenses      = ['MIT']
  spec.authors       = ['Arkency']
  spec.email         = ['dev@arkency.com']

  spec.summary       = %q{Event sourced (with Rails Event Store) aggregate root implementation}
  spec.description   = %q{Event sourced (with Rails Event Store) aggregate root implementation}
  spec.homepage      = ''

  spec.files         = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  spec.bindir        = 'exe'
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ['lib']

  spec.add_development_dependency 'bundler', '~> 1.9'
  spec.add_development_dependency 'rake', '~> 10.0'
  spec.add_development_dependency 'pry'
  spec.add_development_dependency 'rspec'
  spec.add_development_dependency 'rails', '~> 4.2.1'
  spec.add_development_dependency 'ruby_event_store', '~> 0.13.0'
  spec.add_development_dependency 'mutant-rspec', '~> 0.8'

  spec.add_dependency 'activesupport', '>= 3.0'
end
