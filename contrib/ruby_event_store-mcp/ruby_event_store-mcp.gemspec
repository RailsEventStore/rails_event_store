# frozen_string_literal: true

require_relative "lib/ruby_event_store/mcp/version"

Gem::Specification.new do |spec|
  spec.name = "ruby_event_store-mcp"
  spec.version = RubyEventStore::MCP::VERSION
  spec.license = "MIT"
  spec.author = "Arkency"
  spec.email = "dev@arkency.com"
  spec.summary = "Model Context Protocol server for Ruby Event Store"
  spec.homepage = "https://railseventstore.org"
  spec.files = Dir["lib/**/*", "bin/**/*"]
  spec.require_paths = %w[lib]
  spec.extra_rdoc_files = %w[README.md]
  spec.bindir = "bin"
  spec.executables = %w[res-mcp]

  spec.metadata = {
    "homepage_uri" => spec.homepage,
    "source_code_uri" => "https://github.com/RailsEventStore/rails_event_store",
    "bug_tracker_uri" => "https://github.com/RailsEventStore/rails_event_store/issues",
    "rubygems_mfa_required" => "true"
  }

  spec.required_ruby_version = ">= 3.0"

  spec.add_dependency "ruby_event_store", ">= 1.0.0"
end
