require "spec_helper"

module RubyEventStore
  RSpec.describe Browser do
    specify { expect(test_client.get("/")).to be_ok }
    specify { expect(test_client.post("/")).to be_not_found }
    specify { expect(test_client.get("/streams/all")).to be_ok }
    specify do
      event_store.append(DummyEvent.new(event_id: event_id))
      expect(test_client.get("/events/#{event_id}")).to be_ok
    end

    let(:event_store) { RubyEventStore::Client.new(repository: RubyEventStore::InMemoryRepository.new) }
    let(:test_client) { TestClient.new(app_builder(event_store)) }
    let(:event_id) { SecureRandom.uuid }

    def app_builder(event_store)
      RubyEventStore::Browser::App.for(event_store_locator: -> { event_store }, host: "http://www.example.com")
    end
  end
end
