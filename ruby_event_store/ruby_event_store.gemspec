# frozen_string_literal: true

require_relative "lib/ruby_event_store/version"

Gem::Specification.new do |spec|
  spec.name = "ruby_event_store"
  spec.version = RubyEventStore::VERSION
  spec.license = "MIT"
  spec.author = "Arkency"
  spec.email = "dev@arkency.com"
  spec.summary = "Implementation of an event store in Ruby"
  spec.description = <<~EOD
    Ruby implementation of an event store. Ships with in-memory event repository, generic instrumentation
    and dispatches events synchronously.
  EOD
  spec.homepage = "https://railseventstore.org"
  spec.files = Dir["lib/**/*"]
  spec.require_paths = %w[lib]
  spec.extra_rdoc_files = %w[README.md]

  spec.metadata = {
    "homepage_uri" => spec.homepage,
    "changelog_uri" => "https://github.com/RailsEventStore/rails_event_store/releases",
    "source_code_uri" => "https://github.com/RailsEventStore/rails_event_store",
    "bug_tracker_uri" => "https://github.com/RailsEventStore/rails_event_store/issues",
    "rubygems_mfa_required" => "true"
  }

  spec.required_ruby_version = ">= 2.7"

  spec.add_dependency "concurrent-ruby", "~> 1.0", ">= 1.1.6"
  spec.add_development_dependency "ostruct"
end
