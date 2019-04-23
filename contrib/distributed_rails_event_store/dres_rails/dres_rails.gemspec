# frozen_string_literal: true

$LOAD_PATH.append File.expand_path("lib", __dir__)
require "dres_rails/identity"

Gem::Specification.new do |spec|
  spec.name = DresRails::Identity.name
  spec.version = DresRails::Identity.version
  spec.platform = Gem::Platform::RUBY
  spec.authors = ["Robert Pankowecki"]
  spec.email = ["dev@arkency.com"]
  spec.homepage = ""
  spec.summary = ""
  spec.license = "MIT"

  # spec.metadata = {
  #   "source_code_uri" => "lol",
  #   "changelog_uri" => "/blob/master/CHANGES.md",
  #   "bug_tracker_uri" => "/issues"
  # }


  spec.required_ruby_version = "~> 2.3"

  spec.add_dependency "rails", [">= 4.2", "< 6"]
  spec.add_dependency "ruby_event_store"
  spec.add_dependency "rails_event_store"

  spec.add_development_dependency "pry", "~> 0.10"
  spec.add_development_dependency "pry-byebug", "~> 3.5"
  spec.add_development_dependency "rake", "~> 12.3"
  spec.add_development_dependency "rspec-rails", "~> 3.7"
  spec.add_development_dependency "capybara", "~> 3.0"
  spec.add_development_dependency "timecop", "~> 0.9"

  spec.files = Dir["app/**/*", "bin/**/*", "config/**/*", "db/**/*", "lib/**/*", "vendor/**/*"]
  spec.extra_rdoc_files = Dir["README*", "LICENSE*"]
  spec.require_paths = ["lib"]
end
