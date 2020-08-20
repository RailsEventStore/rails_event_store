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
  spec.homepage      = 'https://railseventstore.org'
  spec.metadata = {
    "homepage_uri"    => "https://railseventstore.org/",
    "changelog_uri"   => "https://github.com/RailsEventStore/rails_event_store/releases",
    "source_code_uri" => "https://github.com/RailsEventStore/rails_event_store",
    "bug_tracker_uri" => "https://github.com/RailsEventStore/rails_event_store/issues",
  }

  spec.files         = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  spec.bindir        = 'exe'
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ['lib']

  spec.add_dependency 'ruby_event_store', '= 1.1.1'
end
