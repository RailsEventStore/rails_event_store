# frozen_string_literal: true

require "spec_helper"

module RubyEventStore
  ::RSpec.describe Browser, "stream metadata" do
    let(:event_store) do
      Client.new(repository: StreamMetadataAwareRepository.new(InMemoryRepository.new))
    end
    let(:web_client) { WebClient.new(Browser::App.for(event_store_locator: -> { event_store })) }

    def stream_page(name = "orders")
      web_client.get("/streams/#{name}").body
    end

    specify "stream without metadata shows no badge and no metadata" do
      event_store.append(DummyEvent.new, stream_name: "orders")
      body = stream_page
      expect(body).not_to include("data-stream-metadata")
      expect(body).not_to include("data-badge")
    end

    specify "soft deleted stream gets the deleted badge and its time" do
      event_store.append(DummyEvent.new, stream_name: "orders")
      event_store.soft_delete_stream("orders")
      body = stream_page
      expect(body).to include('data-badge="deleted"')
      expect(body).not_to include('data-badge="tombstoned"')
      expect(body).to include('data-metadata="soft_deleted_at"')
      expect(body).not_to include('data-metadata="tombstoned_at"')
    end

    specify "tombstoned stream gets the tombstoned badge and its time" do
      event_store.append(DummyEvent.new, stream_name: "orders")
      event_store.tombstone_stream("orders")
      body = stream_page
      expect(body).to include('data-badge="tombstoned"')
      expect(body).not_to include('data-badge="deleted"')
      expect(body).to include('data-metadata="tombstoned_at"')
      expect(body).not_to include('data-metadata="soft_deleted_at"')
    end

    specify "soft deleted and tombstoned stream gets both badges" do
      event_store.append(DummyEvent.new, stream_name: "orders")
      event_store.soft_delete_stream("orders")
      event_store.tombstone_stream("orders")
      body = stream_page
      expect(body).to include('data-badge="deleted"', 'data-badge="tombstoned"')
    end

    specify "retention is shown without a badge" do
      event_store.append(DummyEvent.new, stream_name: "orders")
      event_store.set_stream_metadata("orders", max_count: 100, max_age: 3600)
      body = stream_page
      expect(body).not_to include("data-badge")
      expect(body).to match(/data-metadata="max_count">100</)
      expect(body).to match(/data-metadata="max_age">3600 s</)
      expect(body).not_to include('data-metadata="truncate_before"')
    end

    specify "only the retention limit that is set is shown" do
      event_store.append(DummyEvent.new, stream_name: "orders")
      event_store.set_stream_metadata("orders", max_count: 5)
      body = stream_page
      expect(body).to include('data-metadata="max_count"')
      expect(body).not_to include('data-metadata="max_age"')
    end

    specify "truncation boundary is shown" do
      event_store.append([DummyEvent.new, DummyEvent.new, DummyEvent.new], stream_name: "orders")
      event_store.truncate_stream("orders", before: 2)
      body = stream_page
      expect(body).to match(/data-metadata="truncate_before">2</)
      expect(body).not_to include("data-badge")
    end

    specify "reserved streams are readable by URL and have no metadata section" do
      event_store.append(DummyEvent.new, stream_name: "orders")
      event_store.tombstone_stream("orders")
      response = web_client.get("/streams/$$orders")
      expect(response).to be_ok
      expect(response.body).to include("StreamTombstoned")
      expect(response.body).not_to include("data-stream-metadata")
    end

    specify "the global stream shows no metadata" do
      event_store.tombstone_stream("orders")
      expect(web_client.get("/streams/all").body).not_to include("data-stream-metadata")
    end

    specify "event page hides reserved streams" do
      event_store.append(DummyEvent.new, stream_name: "orders")
      event_store.tombstone_stream("orders")
      tombstone = event_store.read.stream("$$orders").first
      body = web_client.get("/events/#{tombstone.event_id}").body
      expect(body).not_to include("$$orders")
      event = event_store.read.stream("orders").first
      expect(web_client.get("/events/#{event.event_id}").body).to include(">orders</a>")
    end

    specify "related streams hide reserved streams" do
      app =
        Browser::App.for(
          event_store_locator: -> { event_store },
          related_streams_query: ->(_) { %w[$$orders visible] },
        )
      body = WebClient.new(app).get("/streams/orders").body
      expect(body).to include(">visible</a>")
      expect(body).not_to include("$$orders")
    end

    specify "client without stream metadata support shows no metadata and no error" do
      plain = Client.new
      plain.append(DummyEvent.new, stream_name: "orders")
      app = Browser::App.for(event_store_locator: -> { plain })
      response = WebClient.new(app).get("/streams/orders")
      expect(response).to be_ok
      expect(response.body).not_to include("data-stream-metadata")
    end

    describe Browser::GetStreamMetadata do
      def call(name, store = event_store)
        described_class.new(event_store: store, stream_name: name).call
      end

      specify "returns nil for a stream without metadata" do
        expect(call("orders")).to be_nil
      end

      specify "returns the metadata of a stream which has some" do
        event_store.set_stream_metadata("orders", max_count: 3)
        expect(call("orders")).to eq(event_store.stream_metadata("orders"))
      end

      specify "returns nil without support in the client" do
        expect(call("orders", Client.new)).to be_nil
      end

      specify "does not ask the client about the global stream or reserved streams" do
        store = instance_double(Client)
        expect(call("all", store)).to be_nil
        expect(call("$$orders", store)).to be_nil
        expect(call("$orders", store)).to be_nil
      end
    end

  end

  ::RSpec.describe Browser do
    specify "reserved_stream? checks the prefix only at the start" do
      expect(Browser.reserved_stream?("$a")).to be(true)
      expect(Browser.reserved_stream?("a$")).to be(false)
      expect(Browser.reserved_stream?("a")).to be(false)
    end
  end
end
