require "spec_helper"

module RubyEventStore
  RSpec.describe Browser do
    specify "first page, newest events descending" do
      events     = 40.times.map { DummyEvent.new }
      first_page = events.reverse.take(20)
      event_store.publish(events, stream_name: "dummy")
      event_store.publish([DummyEvent.new])

      test_client.get "/api/streams/dummy/relationships/events"
      expect(test_client.parsed_body["links"]).to eq({
        "last"  => "http://www.example.com/api/streams/dummy/relationships/events?page%5Bposition%5D=head&page%5Bdirection%5D=forward&page%5Bcount%5D=20",
        "next"  => "http://www.example.com/api/streams/dummy/relationships/events?page%5Bposition%5D=#{first_page[19].event_id}&page%5Bdirection%5D=backward&page%5Bcount%5D=20"
      })
      expect(test_client.parsed_body["data"].size).to eq(20)

      test_client.get "/api/streams/all/relationships/events"
      expect(test_client.parsed_body["links"]).to eq({
        "last"  => "http://www.example.com/api/streams/all/relationships/events?page%5Bposition%5D=head&page%5Bdirection%5D=forward&page%5Bcount%5D=20",
        "next"  => "http://www.example.com/api/streams/all/relationships/events?page%5Bposition%5D=#{first_page[18].event_id}&page%5Bdirection%5D=backward&page%5Bcount%5D=20"
      })
      expect(test_client.parsed_body["data"].size).to eq(20)
    end

    specify "first page, newest events descending" do
      events     = 40.times.map { DummyEvent.new }
      first_page = events.reverse.take(20)
      event_store.publish(events, stream_name: "dummy")
      test_client.get "/api/streams/dummy/relationships/events?page[position]=head&page[direction]=backward&page[count]=20"

      expect(test_client.parsed_body["links"]).to eq({
        "last"  => "http://www.example.com/api/streams/dummy/relationships/events?page%5Bposition%5D=head&page%5Bdirection%5D=forward&page%5Bcount%5D=20",
        "next"  => "http://www.example.com/api/streams/dummy/relationships/events?page%5Bposition%5D=#{first_page.last.event_id}&page%5Bdirection%5D=backward&page%5Bcount%5D=20"
      })
      expect(test_client.parsed_body["data"].size).to eq(20)
    end

    specify "first page, newest events descending" do
      events     = 40.times.map { DummyEvent.new }
      first_page = events.reverse.take(20)
      last_page  = events.reverse.drop(20)
      event_store.publish(events, stream_name: "dummy")
      test_client.get "/api/streams/dummy/relationships/events?page[position]=#{last_page.first.event_id}&page[direction]=forward&page[count]=20"

      expect(test_client.parsed_body["links"]).to eq({
        "last"  => "http://www.example.com/api/streams/dummy/relationships/events?page%5Bposition%5D=head&page%5Bdirection%5D=forward&page%5Bcount%5D=20",
        "next"  => "http://www.example.com/api/streams/dummy/relationships/events?page%5Bposition%5D=#{first_page.last.event_id}&page%5Bdirection%5D=backward&page%5Bcount%5D=20"
      })
      expect(test_client.parsed_body["data"].size).to eq(20)
    end

    specify "last page, oldest events descending" do
      events     = 40.times.map { DummyEvent.new }
      first_page = events.reverse.take(20)
      last_page  = events.reverse.drop(20)
      event_store.publish([DummyEvent.new])
      event_store.publish(events, stream_name: "dummy")

      test_client.get "/api/streams/dummy/relationships/events?page[position]=#{first_page.last.event_id}&page[direction]=backward&page[count]=20"
      expect(test_client.parsed_body["links"]).to eq({
        "first" => "http://www.example.com/api/streams/dummy/relationships/events?page%5Bposition%5D=head&page%5Bdirection%5D=backward&page%5Bcount%5D=20",
        "prev"  => "http://www.example.com/api/streams/dummy/relationships/events?page%5Bposition%5D=#{last_page.first.event_id}&page%5Bdirection%5D=forward&page%5Bcount%5D=20" ,
      })
      expect(test_client.parsed_body["data"].size).to eq(20)

      test_client.get "/api/streams/all/relationships/events?page[position]=#{first_page.last.event_id}&page[direction]=backward&page[count]=20"
      expect(test_client.parsed_body["links"]).to eq({
        "first" => "http://www.example.com/api/streams/all/relationships/events?page%5Bposition%5D=head&page%5Bdirection%5D=backward&page%5Bcount%5D=20",
        "last"  => "http://www.example.com/api/streams/all/relationships/events?page%5Bposition%5D=head&page%5Bdirection%5D=forward&page%5Bcount%5D=20",
        "next"  => "http://www.example.com/api/streams/all/relationships/events?page%5Bposition%5D=#{last_page.last.event_id}&page%5Bdirection%5D=backward&page%5Bcount%5D=20",
        "prev"  => "http://www.example.com/api/streams/all/relationships/events?page%5Bposition%5D=#{last_page.first.event_id}&page%5Bdirection%5D=forward&page%5Bcount%5D=20" ,
      })
      expect(test_client.parsed_body["data"].size).to eq(20)
    end

    specify "last page, oldest events descending" do
      events    = 40.times.map { DummyEvent.new }
      last_page = events.reverse.drop(20)
      event_store.publish(events, stream_name: "dummy")
      test_client.get "/api/streams/dummy/relationships/events?page[position]=head&page[direction]=forward&page[count]=20"

      expect(test_client.parsed_body["links"]).to eq({
        "first" => "http://www.example.com/api/streams/dummy/relationships/events?page%5Bposition%5D=head&page%5Bdirection%5D=backward&page%5Bcount%5D=20",
        "prev"  => "http://www.example.com/api/streams/dummy/relationships/events?page%5Bposition%5D=#{last_page.first.event_id}&page%5Bdirection%5D=forward&page%5Bcount%5D=20",
      })
      expect(test_client.parsed_body["data"].size).to eq(20)
    end

    specify "non-edge page" do
      events = 41.times.map { DummyEvent.new }
      first_page = events.reverse.take(20)
      next_page  = events.reverse.drop(20).take(20)
      event_store.publish(events, stream_name: "dummy")
      test_client.get "/api/streams/dummy/relationships/events?page[position]=#{first_page.last.event_id}&page[direction]=backward&page[count]=20"

      expect(test_client.parsed_body["links"]).to eq({
        "first" => "http://www.example.com/api/streams/dummy/relationships/events?page%5Bposition%5D=head&page%5Bdirection%5D=backward&page%5Bcount%5D=20",
        "last"  => "http://www.example.com/api/streams/dummy/relationships/events?page%5Bposition%5D=head&page%5Bdirection%5D=forward&page%5Bcount%5D=20",
        "next"  => "http://www.example.com/api/streams/dummy/relationships/events?page%5Bposition%5D=#{next_page.last.event_id}&page%5Bdirection%5D=backward&page%5Bcount%5D=20",
        "prev"  => "http://www.example.com/api/streams/dummy/relationships/events?page%5Bposition%5D=#{next_page.first.event_id}&page%5Bdirection%5D=forward&page%5Bcount%5D=20"
      })
      expect(test_client.parsed_body["data"].size).to eq(20)
    end

    specify "smaller than page size" do
      events = [DummyEvent.new, DummyEvent.new]
      event_store.publish(events, stream_name: "dummy")
      test_client.get "/api/streams/dummy/relationships/events"

      expect(test_client.parsed_body["links"]).to eq({})
      expect(test_client.parsed_body["data"].size).to eq(2)
    end

    specify "custom page size" do
      events     = 40.times.map { DummyEvent.new }
      first_page = events.reverse.take(5)
      next_page  = events.reverse.drop(5).take(5)

      event_store.publish(events, stream_name: "dummy")
      test_client.get "/api/streams/dummy/relationships/events?page[position]=#{first_page.last.event_id}&page[direction]=backward&page[count]=5"

      expect(test_client.parsed_body["links"]).to eq({
        "first" => "http://www.example.com/api/streams/dummy/relationships/events?page%5Bposition%5D=head&page%5Bdirection%5D=backward&page%5Bcount%5D=5",
        "last"  => "http://www.example.com/api/streams/dummy/relationships/events?page%5Bposition%5D=head&page%5Bdirection%5D=forward&page%5Bcount%5D=5",
        "next"  => "http://www.example.com/api/streams/dummy/relationships/events?page%5Bposition%5D=#{next_page.last.event_id}&page%5Bdirection%5D=backward&page%5Bcount%5D=5",
        "prev"  => "http://www.example.com/api/streams/dummy/relationships/events?page%5Bposition%5D=#{next_page.first.event_id}&page%5Bdirection%5D=forward&page%5Bcount%5D=5"
      })
      expect(test_client.parsed_body["data"].size).to eq(5)
    end

    specify "custom page size" do
      events = 40.times.map { DummyEvent.new }
      event_store.publish(events, stream_name: "dummy")
      test_client.get "/api/streams/all/relationships/events?page[position]=head&page[direction]=forward&page[count]=5"

      expect(test_client.parsed_body["data"].size).to eq(5)
    end

    specify "out of bounds beyond oldest" do
      events    = 40.times.map { DummyEvent.new }
      last_page = events.reverse.drop(20)
      event_store.publish(events, stream_name: "dummy")
      test_client.get "/api/streams/dummy/relationships/events?page[position]=#{last_page.last.event_id}&page[direction]=backward&page[count]=20"

      expect(test_client.parsed_body["links"]).to eq({})
      expect(test_client.parsed_body["data"].size).to eq(0)
    end

    specify "out of bounds beyond newest" do
      events     = 40.times.map { DummyEvent.new }
      first_page = events.reverse.take(20)
      event_store.publish(events, stream_name: "dummy")
      test_client.get "/api/streams/dummy/relationships/events?page[position]=#{first_page.first.event_id}&page[direction]=forward&page[count]=20"

      expect(test_client.parsed_body["links"]).to eq({})
      expect(test_client.parsed_body["data"].size).to eq(0)
    end

    let(:event_store) { RubyEventStore::Client.new(repository: RubyEventStore::InMemoryRepository.new) }
    let(:test_client) { TestClientWithJsonApiLinter.new(app_builder(event_store)) }

    def app_builder(event_store)
      RubyEventStore::Browser::App.for(
        event_store_locator: -> { event_store },
        host: 'http://www.example.com'
      )
    end
  end
end
