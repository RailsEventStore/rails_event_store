# coding: utf-8
lib = File.expand_path("../lib", __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require "rails_event_store/rspec/version"

Gem::Specification.new do |spec|
  spec.name          = "rails_event_store-rspec"
  spec.version       = RailsEventStore::RSpec::VERSION
  spec.licenses      = ["MIT"]
  spec.authors       = ["Arkency"]
  spec.email         = ["dev@arkency.com"]

  spec.summary       = %q{RSpec matchers for RailsEventStore}

  spec.files         = `git ls-files -z`.split("\x0").reject do |f|
    f.match(%r{^(test|spec|features)/})
  end
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.15"
  spec.add_development_dependency "rake", "~> 10.0"
  spec.add_development_dependency "rspec", "~> 3.0"
  spec.add_development_dependency "mutant-rspec", "~> 0.8.11"
  spec.add_development_dependency "rails", "~> 4.2"
  spec.add_development_dependency "rails_event_store", "~> 0.18.0"

  spec.add_runtime_dependency "rspec", "~> 3.0"
end
