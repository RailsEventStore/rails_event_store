require "spec_helper"

module RubyEventStore
  RSpec.describe Browser do
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
