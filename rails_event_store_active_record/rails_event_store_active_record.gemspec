# frozen_string_literal: true

require_relative "lib/rails_event_store_active_record/version"

Gem::Specification.new do |spec|
  spec.name             = "rails_event_store_active_record"
  spec.version          = RailsEventStoreActiveRecord::VERSION
  spec.license          = "MIT"
  spec.author           = "Arkency"
  spec.email            = "dev@arkency.com"
  spec.summary          = "Active Record events repository for Rails Event Store"
  spec.homepage         = "https://railseventstore.org"
  spec.files            = Dir["lib/**/*"]
  spec.require_paths    = %w[lib]
  spec.extra_rdoc_files = %w[README.md]
  spec.metadata    = {
    "homepage_uri" => "https://railseventstore.org/",
    "changelog_uri" => "https://github.com/RailsEventStore/rails_event_store/releases",
    "source_code_uri" => "https://github.com/RailsEventStore/rails_event_store",
    "bug_tracker_uri" => "https://github.com/RailsEventStore/rails_event_store/issues",
  }

  spec.required_ruby_version = ">= 2.5"

  spec.add_dependency "ruby_event_store",    "= 2.0.0"
  spec.add_dependency "activesupport",       ">= 3.0"
  spec.add_dependency "activemodel",         ">= 3.0"
  spec.add_dependency "activerecord-import", ">= 1.0.2"
end
