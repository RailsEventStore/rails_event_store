# frozen_string_literal: true

require_relative "lib/ruby_event_store/browser/swimlane/version"

Gem::Specification.new do |spec|
  spec.name = "ruby_event_store-browser-swimlane"
  spec.version = RubyEventStore::Browser::Swimlane::VERSION
  spec.license = "MIT"
  spec.author = "Arkency"
  spec.email = "dev@arkency.com"
  spec.summary = "Stream comparison view for the RubyEventStore browser"
  spec.homepage = "https://railseventstore.org"
  spec.files = Dir["lib/**/*"]
  spec.require_paths = ["lib"]
  spec.extra_rdoc_files = %w[README.md]
  spec.metadata = {
    "homepage_uri" => spec.homepage,
    "source_code_uri" => "https://github.com/RailsEventStore/rails_event_store",
    "bug_tracker_uri" => "https://github.com/RailsEventStore/rails_event_store/issues",
    "rubygems_mfa_required" => "true"
  }

  spec.required_ruby_version = ">= 3.2"

  spec.add_dependency "ruby_event_store", ">= 2.0.0"
  spec.add_dependency "ruby_event_store-browser", ">= 3.0.0"
end
