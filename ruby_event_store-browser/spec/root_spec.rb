require "spec_helper"

module RubyEventStore
  RSpec.describe Browser do
    specify { expect(test_client.get("/")).to be_ok }

    let(:event_store) { RubyEventStore::Client.new(repository: RubyEventStore::InMemoryRepository.new) }
    let(:test_client) { TestClient.new(app_builder(event_store)) }

    def app_builder(event_store)
      RubyEventStore::Browser::App.for(event_store_locator: -> { event_store }, host: "http://www.example.com")
    end
  end
end
