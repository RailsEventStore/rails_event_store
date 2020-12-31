# frozen_string_literal: true

require_relative "lib/rails_event_store/version"

Gem::Specification.new do |spec|
  spec.name             = "rails_event_store"
  spec.version          = RailsEventStore::VERSION
  spec.license          = "MIT"
  spec.author           = "Arkency"
  spec.email            = "dev@arkency.com"
  spec.summary          = "Event Store in Ruby"
  spec.description      = "Implementation of Event Store in Ruby"
  spec.homepage         = "https://railseventstore.org"
  spec.files            = Dir["lib/**/*"]
  spec.require_paths    = %w[lib]
  spec.extra_rdoc_files = %w[README.md]

  spec.metadata = {
    "homepage_uri"    => spec.homepage,
    "changelog_uri"   => "https://github.com/RailsEventStore/rails_event_store/releases",
    "source_code_uri" => "https://github.com/RailsEventStore/rails_event_store",
    "bug_tracker_uri" => "https://github.com/RailsEventStore/rails_event_store/issues",
  }

  spec.add_dependency "ruby_event_store",                "= 2.0.0"
  spec.add_dependency "ruby_event_store-browser",        "= 2.0.0"
  spec.add_dependency "rails_event_store_active_record", "= 2.0.0"
  spec.add_dependency "aggregate_root",                  "= 2.0.0"
  spec.add_dependency "activesupport",                   ">= 3.0"
  spec.add_dependency "activemodel",                     ">= 3.0"
  spec.add_dependency "activejob",                       ">= 3.0"
  spec.add_dependency "arkency-command_bus",             ">= 0.4"
end
