# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'rails_event_store/version'

Gem::Specification.new do |spec|
  spec.name          = 'rails_event_store'
  spec.version       = RailsEventStore::VERSION
  spec.licenses      = ['MIT']
  spec.authors       = ['Arkency']
  spec.email         = ['dev@arkency.com']

  spec.summary       = %q{Event Store in Ruby}
  spec.description   = %q{Implementation of Event Store in Ruby}
  spec.homepage      = 'https://github.com/arkency/rails_event_store'

  spec.files         = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  spec.bindir        = 'exe'
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ['lib']

  spec.add_development_dependency 'bundler', '~> 1.9'
  spec.add_development_dependency 'rake', '~> 10.0'
  spec.add_development_dependency 'pry'
  spec.add_development_dependency 'rspec'
  spec.add_development_dependency 'rails', '~> 4.2'
  spec.add_development_dependency 'sqlite3'
  spec.add_development_dependency 'rack-test'

  spec.add_dependency 'ruby_event_store', '~> 0.10.0'
  spec.add_dependency 'rails_event_store_active_record', '~> 0.6.5'
  spec.add_dependency 'aggregate_root', '~> 0.3.1'
  spec.add_dependency 'activesupport', '>= 3.0'
  spec.add_dependency 'activemodel', '>= 3.0'
  spec.add_development_dependency 'mutant-rspec', '~> 0.8'

end
