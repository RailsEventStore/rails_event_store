# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'rails_event_store/version'

Gem::Specification.new do |spec|
  spec.name          = 'rails_event_store'
  spec.version       = RailsEventStore::VERSION
  spec.authors       = ['rybex', 'mpraglowski']
  spec.email         = ['tomek.rybka@gmail.com', 'm@praglowski.com']

  spec.summary       = %q{Implementation of Event Store in Ruby}
  spec.description   = %q{Implementation of Event Store in Ruby}
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
  spec.add_development_dependency 'webmock', '~> 1.21.0'
  spec.add_development_dependency 'sqlite3'

  spec.add_dependency 'ruby_event_store', '>= 0.3.0'
  spec.add_dependency 'aggregate_root', '>= 0.1.0'
  spec.add_dependency 'activesupport', '>= 3.0'
  spec.add_dependency 'activemodel', '>= 3.0'

end
