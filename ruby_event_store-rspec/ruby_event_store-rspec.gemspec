# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'ruby_event_store/rspec/version'

Gem::Specification.new do |spec|
  spec.name          = 'ruby_event_store-rspec'
  spec.version       = RubyEventStore::RSpec::VERSION
  spec.licenses      = ['MIT']
  spec.authors       = ['Arkency']
  spec.email         = ['dev@arkency.com']

  spec.summary       = %q{RSpec matchers for RailsEventStore}
  spec.homepage      = 'https://railseventstore.org'
  spec.metadata    = {
    "homepage_uri" => "https://railseventstore.org/",
    "changelog_uri" => "https://github.com/RailsEventStore/rails_event_store/releases",
    "source_code_uri" => "https://github.com/RailsEventStore/rails_event_store",
    "bug_tracker_uri" => "https://github.com/RailsEventStore/rails_event_store/issues",
  }

  spec.files         = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test/|spec/|features/|.mutant.yml)}) }
  spec.require_paths = ['lib']

  spec.add_runtime_dependency 'rspec', '~> 3.0'
end
