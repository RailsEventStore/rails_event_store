# frozen_string_literal: true

require "spec_helper"

module RubyEventStore
  ::RSpec.describe Browser do
    specify do
      expect { Browser::App.for(event_store_locator: -> { event_store }, environment: :test) }.to output(
        /Passing :environment to RubyEventStore::Browser::App\.for is deprecated/,
      ).to_stderr
    end

    specify do
      expect {
        Browser::App.for(event_store_locator: -> { event_store }, host: "http://localhost:31337")
      }.to output(/Passing :host to RubyEventStore::Browser::App\.for is deprecated/).to_stderr
    end

    specify do
      expect { Browser::App.for(event_store_locator: -> { event_store }, path: "/res") }.to output(
        /Passing :path to RubyEventStore::Browser::App\.for is deprecated/,
      ).to_stderr
    end

    specify do
      expect { Browser::App.for(event_store_locator: -> { event_store }, api_url: "http://example.com/api") }.to output(
        /Passing :api_url to RubyEventStore::Browser::App\.for is deprecated/,
      ).to_stderr
    end

    let(:event_store) { Client.new }
  end
end
