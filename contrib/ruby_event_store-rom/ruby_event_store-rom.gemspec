# frozen_string_literal: true

require_relative "lib/ruby_event_store/rom/version"


Gem::Specification.new do |spec|
  spec.name             = "ruby_event_store-rom"
  spec.version          = RubyEventStore::ROM::VERSION
  spec.license          = "MIT"
  spec.author           = "Joel Van Horn"
  spec.email            = "joel@joelvanhorn.com"
  spec.summary          = "ROM events repository for Ruby Event Store"
  spec.description      = "Implementation of events repository based on ROM for Ruby Event Store"
  spec.homepage         = "https://railseventstore.org"
  spec.files            = Dir["lib/**/*"]
  spec.require_paths    = %w[lib]
  spec.extra_rdoc_files = %w[README.md]

  spec.metadata = {
    "homepage_uri"    => spec.homepage,
    "changelog_uri"   => "https://github.com/RailsEventStore/rails_event_store/blob/master/contrib/ruby_event_store-rom/CHANGELOG.md",
    "source_code_uri" => "https://github.com/RailsEventStore/rails_event_store",
    "bug_tracker_uri" => "https://github.com/RailsEventStore/rails_event_store/issues",
  }

  spec.required_ruby_version = ">= 2.5"

  spec.add_dependency "dry-container", ">= 0.6"
  spec.add_dependency "dry-initializer", ">= 3.0"
  spec.add_dependency "dry-types", ">= 1.0"
  spec.add_dependency "rom-changeset", ">= 5.0"
  spec.add_dependency "rom-repository", ">= 5.0"
  spec.add_dependency "rom-sql", ">= 3.0"
  spec.add_dependency "sequel", ">= 5.11.0"
  spec.add_dependency "ruby_event_store", ">= 2.0.0", "< 3.0.0"
end
