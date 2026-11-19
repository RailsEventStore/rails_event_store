# frozen_string_literal: true

require_relative "lib/ruby_event_store/scavenger/version"

Gem::Specification.new do |spec|
  spec.name = "ruby_event_store-scavenger"
  spec.version = RubyEventStore::Scavenger::VERSION
  spec.license = "MIT"
  spec.author = "Arkency"
  spec.email = "dev@arkency.com"
  spec.summary = "Physical removal of hidden stream entries for Ruby Event Store"
  spec.description = <<~EOD
    Runs apart from the application: hides the entries that stream retention, truncation and soft
    delete leave hidden, and removes their links once a grace period has passed.
  EOD
  spec.homepage = "https://railseventstore.org"
  spec.files = Dir["lib/**/*", "exe/*"]
  spec.require_paths = %w[lib]
  spec.extra_rdoc_files = %w[README.md]
  spec.bindir = "exe"
  spec.executables = %w[res-scavenge]

  spec.metadata = {
    "homepage_uri" => spec.homepage,
    "source_code_uri" => "https://github.com/RailsEventStore/rails_event_store",
    "bug_tracker_uri" => "https://github.com/RailsEventStore/rails_event_store/issues",
    "rubygems_mfa_required" => "true",
  }

  spec.required_ruby_version = ">= 3.3"

  spec.add_dependency "ruby_event_store", ">= 3.2.0"
  spec.add_dependency "ruby_event_store-active_record", ">= 3.2.0"
  spec.add_dependency "activerecord", ">= 7.2"
end
