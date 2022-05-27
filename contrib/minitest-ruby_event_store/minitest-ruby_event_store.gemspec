# frozen_string_literal: true

require_relative "lib/minitest/ruby_event_store/version"

Gem::Specification.new do |spec|
  spec.name = "minitest-ruby_event_store"
  spec.version = Minitest::RubyEventStore::VERSION
  spec.license = "MIT"
  spec.author = "Arkency"
  spec.email = "dev@arkency.com"
  spec.summary = "Minitest assertions for RubyEventStore"
  spec.homepage = "https://railseventstore.org"
  spec.files = Dir["lib/**/*"]
  spec.require_paths = ["lib"]
  spec.extra_rdoc_files = %w[README.md]
  spec.metadata = {
    "homepage_uri" => spec.homepage,
    "source_code_uri" => "https://github.com/RailsEventStore/ruby_event_store",
    "bug_tracker_uri" => "https://github.com/RailsEventStore/ruby_event_store/issues",
    "rubygems_mfa_required" => "true"
  }

  spec.required_ruby_version = ">= 2.6"

  spec.add_development_dependency "minitest", "~> 5.0"
  spec.add_dependency "ruby_event_store", ">= 2.0.0"
end
