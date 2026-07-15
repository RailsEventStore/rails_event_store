# frozen_string_literal: true

require "spec_helper"

module RubyEventStore
  ::RSpec.describe Browser do
    include Browser::IntegrationHelpers

    specify "finds streams matching a prefix" do
      event_store.publish(DummyEvent.new, stream_name: "dummy-1")
      event_store.publish(DummyEvent.new, stream_name: "dummy-2")
      event_store.publish(DummyEvent.new, stream_name: "other")

      response = web_client.get("/search_streams/dummy-")

      expect(response).to be_ok
      expect(response.content_type).to eq("application/json;charset=utf-8")
      expect(JSON.parse(response.body)).to eq({ "streams" => %w[dummy-1 dummy-2] })
    end

    specify "returns nothing for a prefix shorter than the minimum length" do
      event_store.publish(DummyEvent.new, stream_name: "dummy-1")

      response = web_client.get("/search_streams/du")

      expect(response).to be_ok
      expect(JSON.parse(response.body)).to eq({ "streams" => [] })
    end

    specify "returns nothing when nothing matches" do
      event_store.publish(DummyEvent.new, stream_name: "dummy-1")

      response = web_client.get("/search_streams/nope")

      expect(response).to be_ok
      expect(JSON.parse(response.body)).to eq({ "streams" => [] })
    end

    specify "caps results at the configured limit even if the repository returned more" do
      stub_const("RubyEventStore::Browser::SEARCH_STREAMS_LIMIT", 2)
      event_store.publish(DummyEvent.new, stream_name: "dummy-1")
      event_store.publish(DummyEvent.new, stream_name: "dummy-2")
      event_store.publish(DummyEvent.new, stream_name: "dummy-3")

      response = web_client.get("/search_streams/dummy-")

      expect(JSON.parse(response.body).fetch("streams").size).to eq(2)
    end
  end
end
