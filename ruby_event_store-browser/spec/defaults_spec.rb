require 'spec_helper'

module RubyEventStore
  RSpec.describe Browser do
    it "takes path from request" do
      event_store.publish(events = 21.times.map { DummyEvent.new })
      test_client.get "/res/api/streams/all/relationships/events"

      expect(test_client.parsed_body["links"]).to eq({
        "last" => "http://railseventstore.org/res/api/streams/all/relationships/events/head/forward/20",
        "next" => "http://railseventstore.org/res/api/streams/all/relationships/events/#{events[1].event_id}/backward/20"
      })
    end

    it "takes host from request" do
      response = test_client.get '/res'

      expect(response.body).to match %r{<script type="text/javascript" src="/res/ruby_event_store_browser.js"></script>}
    end

    let(:event_store) { RubyEventStore::Client.new(repository: RubyEventStore::InMemoryRepository.new) }
    let(:test_client) { TestClient.new(app_builder(event_store), 'railseventstore.org') }

    def app_builder(event_store)
      Rack::Builder.new do
        map "/res" do
          run RubyEventStore::Browser::App.for(event_store_locator: -> { event_store })
        end
      end
    end
  end
end
