# frozen_string_literal: true

require_relative "lib/ruby_event_store/sidekiq_scheduler/version"

Gem::Specification.new do |spec|
  spec.name             = "ruby_event_store-sidekiq_scheduler"
  spec.version          = RubyEventStore::SidekiqScheduler::VERSION
  spec.license          = "MIT"
  spec.author           = "Arkency"
  spec.email            = "dev@arkency.com"
  spec.summary          = "Ruby Event Store scheduler for sidekiq"
  spec.homepage         = "https://railseventstore.org"
  spec.files            = Dir["lib/**/*"]
  spec.require_paths    = %w[lib]
  spec.extra_rdoc_files = %w[README.md]

  spec.metadata = {
    "homepage_uri"    => spec.homepage,
    "source_code_uri" => "https://github.com/RailsEventStore/rails_event_store",
    "bug_tracker_uri" => "https://github.com/RailsEventStore/rails_event_store/issues",
  }

  spec.required_ruby_version = ">= 2.5"

  spec.add_dependency "ruby_event_store", ">= 2.0.0", "< 3.0.0"
end
