require 'spec_helper'

module RubyEventStore
  RSpec.describe Browser do
    it "takes path from request" do
      event_store.publish(events = 21.times.map { DummyEvent.new })
      test_client.get "/res/api/streams/all/relationships/events"

      expect(test_client.parsed_body["links"]).to eq({
        "last" => "http://railseventstore.org/res/api/streams/all/relationships/events?page%5Bposition%5D=head&page%5Bdirection%5D=forward&page%5Bcount%5D=20",
        "next" => "http://railseventstore.org/res/api/streams/all/relationships/events?page%5Bposition%5D=#{events[1].event_id}&page%5Bdirection%5D=backward&page%5Bcount%5D=20"
      })
    end

    it "takes host from request" do
      response = test_client.get '/res'

      expect(response.body).to match %r{<script type="text/javascript" src="/res/ruby_event_store_browser.js"></script>}
    end

    it "builds api url based on the settings" do
      app = Rack::Builder.new do
        map "/res" do
          run RubyEventStore::Browser::App.for(event_store_locator: -> { event_store }, api_url: "https://example.com/some/custom/api/url")
        end
      end
      test_client = TestClient.new(app, 'railseventstore.org')

      response = test_client.get '/res'

      expect(response.body).to match %r{apiUrl:\s*"https://example.com/some/custom/api/url"}
    end

    it "default #api_url is based on root_path" do
      response = test_client.get '/res'

      expect(response.body).to match %r{apiUrl:\s*"http://railseventstore.org/res/api"}
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
