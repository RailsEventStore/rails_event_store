# frozen_string_literal: true

require_relative "lib/ruby_event_store/cli/version"

Gem::Specification.new do |spec|
  spec.name = "ruby_event_store-cli"
  spec.version = RubyEventStore::CLI::VERSION
  spec.license = "MIT"
  spec.author = "Arkency"
  spec.email = "dev@arkency.com"
  spec.summary = "Command-line interface for Ruby Event Store"
  spec.homepage = "https://railseventstore.org"
  spec.files = Dir["lib/**/*"]
  spec.require_paths = %w[lib]
  spec.extra_rdoc_files = %w[README.md]
  spec.bindir = "bin"
  spec.executables = %w[res]

  spec.metadata = {
    "homepage_uri" => spec.homepage,
    "source_code_uri" => "https://github.com/RailsEventStore/rails_event_store",
    "bug_tracker_uri" => "https://github.com/RailsEventStore/rails_event_store/issues",
    "rubygems_mfa_required" => "true"
  }

  spec.required_ruby_version = ">= 2.7"

  spec.add_dependency "dry-cli", ">= 1.0"
  spec.add_dependency "ruby_event_store", ">= 1.0.0"
end
