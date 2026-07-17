# frozen_string_literal: true

require "spec_helper"

module RubyEventStore
  ::RSpec.describe Browser do
    include Browser::IntegrationHelpers

    specify "renders a column for the primary stream and each compared stream" do
      event_store.publish(DummyEvent.new, stream_name: "dummy")
      event_store.publish(DummyEvent.new, stream_name: "dummy_too")

      body = web_client.get("/streams/dummy?compare[]=dummy_too").body

      expect(body).to include("Comparing dummy, dummy_too")
      expect(body).to include("dummy_too")
      expect(body.scan(%r{/events/}).size).to eq(2)
    end

    specify "falls back to the single-stream view without compare params" do
      event_store.publish(DummyEvent.new, stream_name: "dummy")

      body = web_client.get("/streams/dummy").body

      expect(body).not_to include("Comparing")
    end

    specify "the compare view exposes a more_url when a lane has more events than fit on one page" do
      21.times { event_store.publish(DummyEvent.new, stream_name: "dummy") }
      event_store.publish(DummyEvent.new, stream_name: "dummy_too")

      body = web_client.get("/streams/dummy?compare[]=dummy_too").body

      expect(body).to match(%r{data-swimlane-more-url-value="[^"]*/streams/compare/more\?[^"]+"})
    end

    specify "compare/more returns the next merged page as table rows" do
      21.times { event_store.publish(DummyEvent.new, stream_name: "dummy") }
      event_store.publish(DummyEvent.new, stream_name: "dummy_too")

      response = web_client.get("/streams/compare/more?streams[]=dummy&streams[]=dummy_too")
      json = JSON.parse(response.body)

      expect(json["html"]).to include("<tr>")
      expect(json["more_url"]).to include("/streams/compare/more?")
    end

    specify "compare/more has no more_url once every stream is exhausted" do
      event_store.publish(DummyEvent.new, stream_name: "dummy")

      response = web_client.get("/streams/compare/more?streams[]=dummy")
      json = JSON.parse(response.body)

      expect(json["more_url"]).to be_nil
    end
  end
end
