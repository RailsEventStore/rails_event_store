# frozen_string_literal: true

require_relative "lib/rails_event_store/inspector/version"

Gem::Specification.new do |spec|
  spec.name = "rails_event_store-inspector"
  spec.version = RailsEventStore::Inspector::VERSION
  spec.license = "MIT"
  spec.author = "Arkency"
  spec.email = "dev@arkency.com"
  spec.summary = "Live view of what RailsEventStore did during a request"
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

  spec.required_ruby_version = ">= 3.1"

  spec.add_dependency "rails_event_store", ">= 3.0.0"
  spec.add_dependency "railties", ">= 7.0"
end
