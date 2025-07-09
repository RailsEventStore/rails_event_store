# frozen_string_literal: true

require_relative "lib/ruby_event_store/browser/version"

Gem::Specification.new do |spec|
  spec.name = "ruby_event_store-browser"
  spec.version = RubyEventStore::Browser::VERSION
  spec.license = "MIT"
  spec.author = "Arkency"
  spec.email = "dev@arkency.com"
  spec.summary = "Event browser companion application for RubyEventStore"
  spec.description = <<~EOD
    Event browser companion application for RubyEventStore. Inspect stream contents and event details. 
    Explore correlation and causation connections.
  EOD
  spec.homepage = "https://railseventstore.org"
  spec.files = Dir["lib/**/*"] + %w[
    bootstrap.js
    ruby_event_store_browser.css
    ruby_event_store_browser.js
    android-chrome-192x192.png
    android-chrome-512x512.png
    apple-touch-icon.png
    favicon.ico
    favicon-16x16.png
    favicon-32x32.png
    mstile-70x70.png
    mstile-144x144.png
    mstile-150x150.png
    mstile-310x150.png
    mstile-310x310.png
    safari-pinned-tab.svg
  ].map {|f| "public/#{f}" }
  spec.require_paths = %w[lib]
  spec.extra_rdoc_files = %w[README.md]
  spec.metadata = {
    "homepage_uri" => spec.homepage,
    "changelog_uri" => "https://github.com/RailsEventStore/rails_event_store/releases",
    "source_code_uri" => "https://github.com/RailsEventStore/rails_event_store",
    "bug_tracker_uri" => "https://github.com/RailsEventStore/rails_event_store/issues",
    "rubygems_mfa_required" => "true"
  }

  spec.required_ruby_version = ">= 2.7"

  spec.add_dependency "ruby_event_store", "= 2.17.1"
  spec.add_dependency "rack"
end
