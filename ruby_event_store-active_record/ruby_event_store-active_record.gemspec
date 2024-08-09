# frozen_string_literal: true

require_relative "lib/ruby_event_store/active_record/version"

Gem::Specification.new do |spec|
  spec.name = "ruby_event_store-active_record"
  spec.version = RubyEventStore::ActiveRecord::VERSION
  spec.license = "MIT"
  spec.author = "Arkency"
  spec.email = "dev@arkency.com"
  spec.summary = "Persistent event repository implementation for RubyEventStore based on ActiveRecord"
  spec.description = <<~EOD
    Persistent event repository implementation for RubyEventStore based on ActiveRecord. Ships with database schema
    and migrations suitable for PostgreSQL, MySQL ans SQLite database engines.

    Includes repository implementation with linearized writes to achieve log-like properties of streams
    on top of SQL database engine.
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

  spec.add_dependency "ruby_event_store", "= 2.15.0"
  spec.add_dependency "activerecord", ">= 6.0"
end
