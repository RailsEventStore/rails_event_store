# frozen_string_literal: true

require "digest"

module RubyEventStore
  module Browser
    PAGE_SIZE = 20
    SERIALIZED_GLOBAL_STREAM_NAME = "all".freeze
    DEFAULT_RELATED_STREAMS_QUERY = ->(stream_name) { [] }

    ASSETS_ROOT = File.expand_path("../../public", __dir__).freeze

    def self.fingerprint(name)
      base, ext = name.split(".", 2)
      digest = Digest::MD5.hexdigest(File.binread(File.join(ASSETS_ROOT, name)))[0, 8]
      "#{base}-#{digest}.#{ext}"
    end

    BROWSER_JS  = fingerprint("ruby_event_store_browser.js")
    BROWSER_CSS = fingerprint("ruby_event_store_browser.css")
  end
end

require_relative "browser/get_events_from_stream"
require_relative "browser/urls"
require_relative "browser/router"
require_relative "browser/renderer"
