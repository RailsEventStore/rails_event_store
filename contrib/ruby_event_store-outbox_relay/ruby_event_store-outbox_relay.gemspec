# frozen_string_literal: true

require_relative "lib/ruby_event_store/outbox_relay/version"

Gem::Specification.new do |spec|
  spec.name = "ruby_event_store-outbox_relay"
  spec.version = RubyEventStore::OutboxRelay::VERSION
  spec.license = "MIT"
  spec.author = "Arkency"
  spec.email = "dev@arkency.com"
  spec.summary = "Transactional outbox relay for Ruby Event Store, built on top of published_at column"
  spec.homepage = "https://railseventstore.org"
  spec.files = Dir["lib/**/*"]
  spec.require_paths = %w[lib]
  spec.bindir = "bin"
  spec.executables = %w[res_outbox_relay]

  spec.metadata = {
    "homepage_uri" => spec.homepage,
    "source_code_uri" => "https://github.com/RailsEventStore/rails_event_store",
    "bug_tracker_uri" => "https://github.com/RailsEventStore/rails_event_store/issues",
    "rubygems_mfa_required" => "true",
  }

  spec.required_ruby_version = ">= 3.3"

  spec.add_dependency "ruby_event_store", ">= 3.0.0"
  spec.add_dependency "ruby_event_store-active_record", ">= 3.0.0"
  spec.add_dependency "rails_event_store", ">= 3.0.0"
  spec.add_dependency "activerecord", ">= 7.1"
end
