require "spec_helper"

module RubyEventStore
  RSpec.describe Browser do
    specify "requsting stream resource" do
      test_client.get "/streams/all"

      expect(test_client.last_response).to be_ok
      expect(test_client.parsed_body["data"]).to eq({
        "id" => "all",
        "type" => "streams",
        "attributes" => {
          "related_streams" => nil,
        },
        "relationships" => {
          "events" => {
            "links" => {
              "self" => "http://www.example.com/streams/all/relationships/events",
            }
          }
        }
      })
    end

    specify "requsting stream resource with related streams" do
      app = RubyEventStore::Browser::App.for(
        event_store_locator: -> { event_store },
        related_streams_query: ->(stream_name) { stream_name == "dummy" ? ["even-dummier"] : [] },
        host: 'http://www.example.com'
      )
      test_client = TestClient.with_linter(app)

      test_client.get "/streams/all"
      expect(test_client.last_response).to be_ok
      expect(test_client.parsed_body["data"]["attributes"]["related_streams"]).to eq([])

      test_client.get "/streams/dummy"
      expect(test_client.last_response).to be_ok
      expect(test_client.parsed_body["data"]["attributes"]["related_streams"]).to eq(["even-dummier"])
    end

    specify "default related streams query returns nil" do
      app = RubyEventStore::Browser::App.for(
        event_store_locator: -> { event_store },
        host: 'http://www.example.com'
      )
      test_client = TestClient.with_linter(app)

      test_client.get "/streams/all"
      expect(test_client.last_response).to be_ok
      expect(test_client.parsed_body["data"]["attributes"]["related_streams"]).to eq(nil)
    end

    specify do
      event_store.publish(dummy_event, stream_name: "dummy")
      test_client.get "/streams/all/relationships/events"

      expect(test_client.last_response).to be_ok
      expect(test_client.parsed_body["data"]).to match_array([event_resource])

      test_client.get "/streams/dummy/relationships/events"

      expect(test_client.last_response).to be_ok
      expect(test_client.parsed_body["data"]).to match_array([event_resource])
    end

    specify do
      event_store.publish(dummy_event, stream_name: "dummy")
      test_client.get "/events/#{dummy_event.event_id}"

      expect(test_client.last_response).to be_ok
      expect(test_client.parsed_body["data"]).to match(event_resource)
    end

    specify "requesting event with correlation stream" do
      event = DummyEvent.new(
        event_id: "a562dc5c-97c0-4fe9-8b81-10f9bd0e825f",
        data: {},
        metadata: {
          correlation_id: "a7243789-999f-4ef2-8511-b1c686b83fad"
        }
      )
      event_store.publish(event, stream_name: "dummy")
      test_client.get "/events/#{event.event_id}"

      expect(test_client.last_response).to be_ok
      expect(test_client.parsed_body["data"]["attributes"]["correlation_stream_name"]).to eq(
        "$by_correlation_id_a7243789-999f-4ef2-8511-b1c686b83fad",
      )
    end

    specify "requesting event with causation stream" do
      event = DummyEvent.new(
        event_id: "a562dc5c-97c0-4fe9-8b81-10f9bd0e825f",
        data: {},
      )
      event_store.publish(event, stream_name: "dummy")
      test_client.get "/events/#{event.event_id}"

      expect(test_client.last_response).to be_ok
      expect(test_client.parsed_body["data"]["attributes"]["causation_stream_name"]).to eq(
        "$by_causation_id_a562dc5c-97c0-4fe9-8b81-10f9bd0e825f",
      )
    end

    specify "requesting event with parent event id" do
      parent_event = DummyEvent.new(
        event_id: "44427ded-e8a7-4ee4-bf31-09f34433d506",
        data: {},
      )
      event_store.publish(parent_event, stream_name: "dummy")
      caused_event = DummyEvent.new(
        event_id: "a562dc5c-97c0-4fe9-8b81-10f9bd0e825f",
        data: {},
        metadata: {
          causation_id: parent_event.event_id,
        }
      )
      event_store.publish(caused_event, stream_name: "dummy")
      test_client.get "/events/#{caused_event.event_id}"

      expect(test_client.last_response).to be_ok
      expect(test_client.parsed_body["data"]["attributes"]["parent_event_id"]).to eq(
        "44427ded-e8a7-4ee4-bf31-09f34433d506",
      )
    end

    specify "requesting event which is caused by something other than event" do
      caused_event = DummyEvent.new(
        event_id: "a562dc5c-97c0-4fe9-8b81-10f9bd0e825f",
        data: {},
        metadata: {
          causation_id: "44427ded-e8a7-4ee4-bf31-09f34433d506",
        }
      )
      event_store.publish(caused_event, stream_name: "dummy")
      test_client.get "/events/#{caused_event.event_id}"

      expect(test_client.last_response).to be_ok
      expect(test_client.parsed_body["data"]["attributes"]["parent_event_id"]).to be_nil
    end

    specify "requesting non-existing event" do
      test_client.get "/events/73947fbd-90d7-4e1c-be2a-d7ff1900c409"

      test_client.last_response
      expect(test_client.last_response).to be_not_found
      expect(test_client.last_response.body).to be_empty
    end

    specify do
      json = Browser::JsonApiEvent.new(dummy_event("a562dc5c-97c0-4fe9-8b81-10f9bd0e825f"), nil).to_h

      expect(json).to match(
        id: "a562dc5c-97c0-4fe9-8b81-10f9bd0e825f",
        type: "events",
        attributes: {
          event_type: "DummyEvent",
          data: {
            foo: 1,
            bar: 2.0,
            baz: "3"
          },
          metadata: {},
          correlation_stream_name: nil,
          causation_stream_name: "$by_causation_id_a562dc5c-97c0-4fe9-8b81-10f9bd0e825f",
          parent_event_id: nil,
          type_stream_name: "$by_type_DummyEvent",
        },
      )
    end

    specify "first page, newest events descending" do
      events     = 40.times.map { DummyEvent.new }
      first_page = events.reverse.take(20)
      event_store.publish(events, stream_name: "dummy")
      event_store.publish([DummyEvent.new])

      test_client.get "/streams/dummy/relationships/events"
      expect(test_client.parsed_body["links"]).to eq({
        "last"  => "http://www.example.com/streams/dummy/relationships/events/head/forward/20",
        "next"  => "http://www.example.com/streams/dummy/relationships/events/#{first_page[19].event_id}/backward/20"
      })
      expect(test_client.parsed_body["data"].size).to eq(20)

      test_client.get "/streams/all/relationships/events"
      expect(test_client.parsed_body["links"]).to eq({
        "last"  => "http://www.example.com/streams/all/relationships/events/head/forward/20",
        "next"  => "http://www.example.com/streams/all/relationships/events/#{first_page[18].event_id}/backward/20"
      })
      expect(test_client.parsed_body["data"].size).to eq(20)
    end

    specify "first page, newest events descending" do
      events     = 40.times.map { DummyEvent.new }
      first_page = events.reverse.take(20)
      event_store.publish(events, stream_name: "dummy")
      test_client.get "/streams/dummy/relationships/events/head/backward/20"

      expect(test_client.parsed_body["links"]).to eq({
        "last"  => "http://www.example.com/streams/dummy/relationships/events/head/forward/20",
        "next"  => "http://www.example.com/streams/dummy/relationships/events/#{first_page.last.event_id}/backward/20"
      })
      expect(test_client.parsed_body["data"].size).to eq(20)
    end

    specify "first page, newest events descending" do
      events     = 40.times.map { DummyEvent.new }
      first_page = events.reverse.take(20)
      last_page  = events.reverse.drop(20)
      event_store.publish(events, stream_name: "dummy")
      test_client.get "/streams/dummy/relationships/events/#{last_page.first.event_id}/forward/20"

      expect(test_client.parsed_body["links"]).to eq({
        "last"  => "http://www.example.com/streams/dummy/relationships/events/head/forward/20",
        "next"  => "http://www.example.com/streams/dummy/relationships/events/#{first_page.last.event_id}/backward/20"
      })
      expect(test_client.parsed_body["data"].size).to eq(20)
    end

    specify "last page, oldest events descending" do
      events     = 40.times.map { DummyEvent.new }
      first_page = events.reverse.take(20)
      last_page  = events.reverse.drop(20)
      event_store.publish([DummyEvent.new])
      event_store.publish(events, stream_name: "dummy")

      test_client.get "/streams/dummy/relationships/events/#{first_page.last.event_id}/backward/20"
      expect(test_client.parsed_body["links"]).to eq({
        "first" => "http://www.example.com/streams/dummy/relationships/events/head/backward/20",
        "prev"  => "http://www.example.com/streams/dummy/relationships/events/#{last_page.first.event_id}/forward/20" ,
      })
      expect(test_client.parsed_body["data"].size).to eq(20)

      test_client.get "/streams/all/relationships/events/#{first_page.last.event_id}/backward/20"
      expect(test_client.parsed_body["links"]).to eq({
        "first" => "http://www.example.com/streams/all/relationships/events/head/backward/20",
        "last"  => "http://www.example.com/streams/all/relationships/events/head/forward/20",
        "next"  => "http://www.example.com/streams/all/relationships/events/#{last_page.last.event_id}/backward/20",
        "prev"  => "http://www.example.com/streams/all/relationships/events/#{last_page.first.event_id}/forward/20" ,
      })
      expect(test_client.parsed_body["data"].size).to eq(20)
    end

    specify "last page, oldest events descending" do
      events    = 40.times.map { DummyEvent.new }
      last_page = events.reverse.drop(20)
      event_store.publish(events, stream_name: "dummy")
      test_client.get "/streams/dummy/relationships/events/head/forward/20"

      expect(test_client.parsed_body["links"]).to eq({
        "first" => "http://www.example.com/streams/dummy/relationships/events/head/backward/20",
        "prev"  => "http://www.example.com/streams/dummy/relationships/events/#{last_page.first.event_id}/forward/20",
      })
      expect(test_client.parsed_body["data"].size).to eq(20)
    end

    specify "non-edge page" do
      events = 41.times.map { DummyEvent.new }
      first_page = events.reverse.take(20)
      next_page  = events.reverse.drop(20).take(20)
      event_store.publish(events, stream_name: "dummy")
      test_client.get "/streams/dummy/relationships/events/#{first_page.last.event_id}/backward/20"

      expect(test_client.parsed_body["links"]).to eq({
        "first" => "http://www.example.com/streams/dummy/relationships/events/head/backward/20",
        "last"  => "http://www.example.com/streams/dummy/relationships/events/head/forward/20",
        "next"  => "http://www.example.com/streams/dummy/relationships/events/#{next_page.last.event_id}/backward/20",
        "prev"  => "http://www.example.com/streams/dummy/relationships/events/#{next_page.first.event_id}/forward/20"
      })
      expect(test_client.parsed_body["data"].size).to eq(20)
    end

    specify "smaller than page size" do
      events = [DummyEvent.new, DummyEvent.new]
      event_store.publish(events, stream_name: "dummy")
      test_client.get "/streams/dummy/relationships/events"

      expect(test_client.parsed_body["links"]).to eq({})
      expect(test_client.parsed_body["data"].size).to eq(2)
    end

    specify "custom page size" do
      events     = 40.times.map { DummyEvent.new }
      first_page = events.reverse.take(5)
      next_page  = events.reverse.drop(5).take(5)

      event_store.publish(events, stream_name: "dummy")
      test_client.get "/streams/dummy/relationships/events/#{first_page.last.event_id}/backward/5"

      expect(test_client.parsed_body["links"]).to eq({
        "first" => "http://www.example.com/streams/dummy/relationships/events/head/backward/5",
        "last"  => "http://www.example.com/streams/dummy/relationships/events/head/forward/5",
        "next"  => "http://www.example.com/streams/dummy/relationships/events/#{next_page.last.event_id}/backward/5",
        "prev"  => "http://www.example.com/streams/dummy/relationships/events/#{next_page.first.event_id}/forward/5"
      })
      expect(test_client.parsed_body["data"].size).to eq(5)
    end

    specify "custom page size" do
      events = 40.times.map { DummyEvent.new }
      event_store.publish(events, stream_name: "dummy")
      test_client.get "/streams/all/relationships/events/head/forward/5"

      expect(test_client.parsed_body["data"].size).to eq(5)
    end

    specify "out of bounds beyond oldest" do
      events    = 40.times.map { DummyEvent.new }
      last_page = events.reverse.drop(20)
      event_store.publish(events, stream_name: "dummy")
      test_client.get "/streams/dummy/relationships/events/#{last_page.last.event_id}/backward/20"

      expect(test_client.parsed_body["links"]).to eq({})
      expect(test_client.parsed_body["data"].size).to eq(0)
    end

    specify "out of bounds beyond newest" do
      events     = 40.times.map { DummyEvent.new }
      first_page = events.reverse.take(20)
      event_store.publish(events, stream_name: "dummy")
      test_client.get "/streams/dummy/relationships/events/#{first_page.first.event_id}/forward/20"

      expect(test_client.parsed_body["links"]).to eq({})
      expect(test_client.parsed_body["data"].size).to eq(0)
    end

    def dummy_event(id = SecureRandom.uuid)
      @dummy_event ||= DummyEvent.new(
        event_id: id,
        data: {
          foo: 1,
          bar: 2.0,
          baz: "3"
        }
      )
    end

    def event_resource
      {
        "id" => dummy_event.event_id,
        "type" => "events",
        "attributes" => {
          "event_type" => "DummyEvent",
          "data" => {
            "foo" => 1,
            "bar" => 2.0,
            "baz" => "3"
          },
          "metadata" => {
            "timestamp" => dummy_event.metadata[:timestamp].iso8601(3)
          },
          "correlation_stream_name" => nil,
          "causation_stream_name" => "$by_causation_id_#{dummy_event.event_id}",
          "parent_event_id" => nil,
          "type_stream_name" => "$by_type_DummyEvent",
        },
      }
    end

    let(:app) { JsonApiLint.new(app_builder(event_store)) }
    let(:event_store) { RubyEventStore::Client.new(repository: RubyEventStore::InMemoryRepository.new) }
    let(:test_client) { TestClient.with_linter(app_builder(event_store)) }

    def app_builder(event_store)
      RubyEventStore::Browser::App.for(
        event_store_locator: -> { event_store },
        host: 'http://www.example.com'
      )
    end
  end
end
