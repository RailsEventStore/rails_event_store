# frozen_string_literal: true

require_relative "lib/ruby_event_store/sequel/version"

Gem::Specification.new do |spec|
  spec.name = "ruby_event_store-sequel"
  spec.version = RubyEventStore::Sequel::VERSION
  spec.license = "MIT"
  spec.authors = ["Arkency"]
  spec.email = ["dev@arkency.com"]
  spec.summary = "Sequel-based event repository for Ruby Event Store"
  spec.description = "Implementation of events repository based on Sequel for Ruby Event Store"
  spec.homepage = "https://railseventstore.org"
  spec.files = Dir["lib/**/*"]
  spec.require_paths = %w[lib]
  spec.extra_rdoc_files = %w[README.md]

  spec.metadata = {
    "homepage_uri" => spec.homepage,
    "changelog_uri" =>
      "https://github.com/RailsEventStore/rails_event_store/blob/master/contrib/ruby_event_store-sequel/CHANGELOG.md",
    "source_code_uri" => "https://github.com/RailsEventStore/rails_event_store",
    "bug_tracker_uri" => "https://github.com/RailsEventStore/rails_event_store/issues",
    "rubygems_mfa_required" => "true"
  }

  spec.required_ruby_version = ">= 2.7"

  spec.add_dependency "sequel", "~> 5.11"
  spec.add_dependency "ruby_event_store", ">= 2.0.0", "< 3.0.0"
end
