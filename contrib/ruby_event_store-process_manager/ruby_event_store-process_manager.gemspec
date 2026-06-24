# frozen_string_literal: true

require_relative "lib/ruby_event_store/process_manager/version"

Gem::Specification.new do |spec|
  spec.name = "ruby_event_store-process_manager"
  spec.version = RubyEventStore::ProcessManager::VERSION
  spec.license = "MIT"
  spec.author = "Arkency"
  spec.email = "dev@arkency.com"
  spec.summary = "Stateful process manager with event-sourced state for RubyEventStore"
  spec.homepage = "https://railseventstore.org"
  spec.files = Dir["lib/**/*"]
  spec.require_paths = %w[lib]
  spec.extra_rdoc_files = %w[README.md]
  spec.metadata = {
    "homepage_uri" => spec.homepage,
    "source_code_uri" => "https://github.com/RailsEventStore/rails_event_store",
    "bug_tracker_uri" => "https://github.com/RailsEventStore/rails_event_store/issues",
    "rubygems_mfa_required" => "true"
  }

  spec.required_ruby_version = ">= 2.7"

  spec.add_dependency "ruby_event_store", ">= 1.0.0", "< 3.0.0"
end
