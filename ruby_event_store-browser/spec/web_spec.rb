# frozen_string_literal: true

require "spec_helper"

module RubyEventStore
  ::RSpec.describe Browser do
    include Browser::IntegrationHelpers

    specify { expect(web_client.get("/")).to be_redirect }

    specify do
      response = web_client.get("/")
      expect(response.location).to end_with("/streams/all")
      expect(response.body).to eq("")
    end

    specify { expect(web_client.get("/streams/all")).to be_ok }

    specify { expect(web_client.get("/streams/all").content_type).to eq("text/html;charset=utf-8") }

    specify do
      event_store.append(DummyEvent.new, stream_name: "test-stream")
      expect(web_client.get("/streams/test-stream").body).to include("Events in test-stream")
    end

    specify do
      event_store.append(event = DummyEvent.new)
      expect(web_client.get("/streams/all").body).to include(event.event_id)
    end

    specify do
      response = web_client.post("/")
      expect(response).to be_not_found
      expect(response.body).to eq("")
    end

    specify do
      event_store.append(event = DummyEvent.new)
      expect(web_client.get("/events/#{event.event_id}")).to be_ok
    end

    specify do
      event_store.append(event = DummyEvent.new)
      response = web_client.get("/events/#{event.event_id}")
      expect(response.body).to include(event.event_id)
      expect(response.body).to include(event.metadata[:timestamp].iso8601(RubyEventStore::TIMESTAMP_PRECISION))
      expect(response.body).to include("valid_at")
    end

    specify "event page lists streams the event belongs to" do
      event_store.append(event = DummyEvent.new, stream_name: "my-stream")
      expect(web_client.get("/events/#{event.event_id}").body).to include("my-stream")
    end

    specify "pagination links contain stream name, position and count" do
      event_store.append(Array.new(Browser::PAGE_SIZE + 1) { DummyEvent.new }, stream_name: "my-stream")
      body = web_client.get("/streams/my-stream").body
      expect(body).to include("streams/my-stream?page%5Bposition%5D")
      expect(body).to include("page%5Bcount%5D=#{Browser::PAGE_SIZE}")
    end

    specify "uses page count param from query string" do
      e1 = DummyEvent.new
      e2 = DummyEvent.new
      event_store.append([e1, e2])

      body = web_client.get("/streams/all?page%5Bcount%5D=1").body
      expect(body).to include(e2.event_id)
      expect(body).not_to include(e1.event_id)
    end

    specify "event page links to parent event via causation_id" do
      parent = DummyEvent.new
      child = DummyEvent.new(metadata: { causation_id: parent.event_id })
      event_store.append([parent, child])
      body = web_client.get("/events/#{child.event_id}").body
      expect(body).to include("Parent event:")
      expect(body).to include(parent.event_id)
    end

    specify "event page lists events caused by this event" do
      parent = DummyEvent.new
      child = DummyEvent.new
      event_store.append([parent, child])
      event_store.link([child.event_id], stream_name: "$by_causation_id_#{parent.event_id}")
      body = web_client.get("/events/#{parent.event_id}").body
      expect(body).to include(child.event_id)
    end

    specify "event page caused_by shows only directly caused events" do
      parent = DummyEvent.new
      child = DummyEvent.new
      unrelated = DummyEvent.new
      event_store.append([parent, child, unrelated])
      event_store.link([child.event_id], stream_name: "$by_causation_id_#{parent.event_id}")
      body = web_client.get("/events/#{parent.event_id}").body
      expect(body).to include(child.event_id)
      expect(body).not_to include(unrelated.event_id)
    end

    specify "event page lists streams in sorted order" do
      event = DummyEvent.new
      event_store.append(event, stream_name: "z-first")
      event_store.link(event.event_id, stream_name: "a-second")
      body = web_client.get("/events/#{event.event_id}").body
      expect(body.index("a-second")).to be < body.index("z-first")
    end

    specify "event page caused_by lists most recent caused events first" do
      parent = DummyEvent.new
      first_child = DummyEvent.new
      second_child = DummyEvent.new
      event_store.append([parent, first_child, second_child])
      event_store.link([first_child.event_id], stream_name: "$by_causation_id_#{parent.event_id}")
      event_store.link([second_child.event_id], stream_name: "$by_causation_id_#{parent.event_id}")
      body = web_client.get("/events/#{parent.event_id}").body
      expect(body.index(second_child.event_id)).to be < body.index(first_child.event_id)
    end

    specify "event page caused_by is limited to PAGE_SIZE" do
      parent = DummyEvent.new
      children = Array.new(Browser::PAGE_SIZE + 1) { DummyEvent.new }
      event_store.append([parent, *children])
      children.each { |c| event_store.link([c.event_id], stream_name: "$by_causation_id_#{parent.event_id}") }
      body = web_client.get("/events/#{parent.event_id}").body
      expect(body).to include("results may be truncated")
    end

    specify "not found page uses absolute url from request for assets" do
      response = web_client.get("/events/00000000-0000-0000-0000-000000000000")
      expect(response.body).to include("http://www.example.com")
    end

    specify "related_streams_query is called with the stream name" do
      called_with = []
      app =
        Browser::App.for(
          event_store_locator: -> { event_store },
          related_streams_query: ->(name) { called_with << name; [] },
        )
      Rack::MockRequest.new(app).get("/streams/my-stream")
      expect(called_with).to include("my-stream")
    end

    specify do
      response = web_client.get("/events/00000000-0000-0000-0000-000000000000")
      expect(response).to be_not_found
      expect(response.content_type).to eq("text/html;charset=utf-8")
      expect(response.body).to include("There's no event with given ID")
      expect(response.body.scan("<!DOCTYPE").size).to eq(1)
    end

    specify "uses configured host for generated URLs" do
      app =
        Browser::App.new(
          event_store_locator: -> { event_store },
          related_streams_query: Browser::DEFAULT_RELATED_STREAMS_QUERY,
          host: "http://configured.example.com",
          root_path: nil,
        )
      env = Rack::MockRequest.env_for("http://other.example.com/")
      status, headers, = app.call(env)
      expect(status).to eq(302)
      expect(headers["location"]).to include("configured.example.com")
    end
  end
end
