# frozen_string_literal: true

require_relative "lib/rails_event_store/hotwire_browser/version"

Gem::Specification.new do |spec|
  spec.name = "rails_event_store-hotwire_browser"
  spec.version = RailsEventStore::HotwireBrowser::VERSION
  spec.license = "MIT"
  spec.author = "Arkency"
  spec.email = "dev@arkency.com"
  spec.summary = "Event browser companion application for RailsEventStore"
  spec.description = <<~EOD
    Event browser companion application for RailsEventStore. Inspect stream contents and event details.
    Explore correlation and causation connections. Mounts as a Rails engine.
  EOD
  spec.homepage = "https://railseventstore.org"
  spec.files = Dir["lib/**/*"] + Dir["app/**/*"] + Dir["config/**/*"] + %w[
    rails_event_store_hotwire_browser.css
    stimulus.js
    browser.js
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
  ].map { |f| "public/#{f}" }
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

  spec.add_dependency "ruby_event_store", ">= 3.0.0"
  spec.add_dependency "rack"
  spec.add_dependency "railties", ">= 7.0"
  spec.add_dependency "actionpack", ">= 7.0"
  spec.add_dependency "actionview", ">= 7.0"
end
