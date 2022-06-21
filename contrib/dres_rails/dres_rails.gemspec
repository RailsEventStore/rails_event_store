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
  spec.files = Dir["app/**/*", "bin/**/*", "config/**/*", "db/**/*", "lib/**/*", "vendor/**/*"]
  spec.extra_rdoc_files = Dir["README*", "LICENSE*"]
  spec.require_paths = ["lib"]

  spec.required_ruby_version = ">= 2.7"

  spec.add_dependency "rails", ">= 6.0", "< 8.0"
  spec.add_dependency "ruby_event_store", ">= 2.0", "< 3.0"
  spec.add_dependency "rails_event_store", ">= 2.0", "< 3.0"
end
