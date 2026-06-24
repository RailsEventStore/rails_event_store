# frozen_string_literal: true

require_relative "lib/dres_rails/identity"

Gem::Specification.new do |spec|
  spec.name = "dres_rails"
  spec.version = DresRails::VERSION
  spec.license = "MIT"
  spec.authors = ["Robert Pankowecki"]
  spec.email = ["dev@arkency.com"]
  spec.homepage = ""
  spec.summary = ""
  spec.files = Dir["app/**/*", "bin/**/*", "config/**/*", "db/**/*", "lib/**/*", "vendor/**/*"]
  spec.extra_rdoc_files = Dir["README*", "LICENSE*"]
  spec.require_paths = ["lib"]

  spec.required_ruby_version = ">= 2.7"

  spec.add_dependency "rails", ">= 6.0", "< 8.0"
  spec.add_dependency "ruby_event_store", ">= 2.0", "< 3.0"
  spec.add_dependency "rails_event_store", ">= 2.0", "< 3.0"
end
