require "spec_helper"

module RubyEventStore
  RSpec.describe Browser do
    it "takes path from request" do
      event_store.publish(events = 21.times.map { DummyEvent.new })
      test_client.get "/res/api/streams/all/relationships/events"

      expect(test_client.parsed_body["links"]).to eq(
        {
          "last" =>
            "http://railseventstore.org/res/api/streams/all/relationships/events?page%5Bposition%5D=head&page%5Bdirection%5D=forward&page%5Bcount%5D=20",
          "next" =>
            "http://railseventstore.org/res/api/streams/all/relationships/events?page%5Bposition%5D=#{events[1].event_id}&page%5Bdirection%5D=backward&page%5Bcount%5D=20"
        }
      )
    end

    it "takes host from request" do
      response = test_client.get "/res"

      expect(response.body).to match %r{<script type="text/javascript" src="/res/ruby_event_store_browser.js"></script>}
    end

    it "builds api url based on the settings" do
      inside_app =
        RubyEventStore::Browser::App.for(
          event_store_locator: -> { event_store },
          api_url: "https://example.com/some/custom/api/url"
        )
      outside_app =
        Rack::Lint.new(
          Rack::Builder.new do
            map "/res" do
              run inside_app
            end
          end
        )

      response = TestClient.new(outside_app, "railseventstore.org").get("/res")

      expect(parsed_meta_content(response.body)["apiUrl"]).to eq("https://example.com/some/custom/api/url")
    end

    it "builds root url based on the settings" do
      app =
        Rack::Lint.new(
          RubyEventStore::Browser::App.for(
            event_store_locator: -> { event_store },
            path: "/home"
          )
        )

      response = TestClient.new(app, "localhost").get("/")

      expect(parsed_meta_content(response.body)["rootUrl"]).to eq("http://localhost/home")
    end

    it "passes RES version" do
      response = test_client.get "/res"

      expect(parsed_meta_content(response.body)["resVersion"]).to eq(RubyEventStore::VERSION)
    end

    it "passes root_url" do
      response = test_client.get "/res"

      expect(parsed_meta_content(response.body)["rootUrl"]).to eq("http://railseventstore.org/res")
    end

    it "default #api_url is based on root_path" do
      response = test_client.get "/res"

      expect(parsed_meta_content(response.body)["apiUrl"]).to eq("http://railseventstore.org/res/api")
    end

    it "default JS sources are based on root_path" do
      response = test_client.get "/res"

      script_tags(response.body).each { |script| expect(script.attribute("src").value).to match %r{\A/res} }

      expect(parsed_meta_content(response.body)["apiUrl"]).to eq("http://railseventstore.org/res/api")
    end

    let(:event_store) { RubyEventStore::Client.new(repository: RubyEventStore::InMemoryRepository.new) }
    let(:test_client) { TestClient.new(app_builder(event_store), "railseventstore.org") }

    def script_tags(response_body)
      Nokogiri.HTML(response_body).css("script")
    end

    def meta_content(response_body)
      Nokogiri.HTML(response_body).css("meta[name='ruby-event-store-browser-settings']").attribute("content")
    end

    def parsed_meta_content(response_body)
      JSON.parse(meta_content(response_body))
    end

    def app_builder(event_store)
      inside_app = RubyEventStore::Browser::App.for(event_store_locator: -> { event_store })
      Rack::Lint.new(
        Rack::Builder.new do
          map "/res" do
            run inside_app
          end
        end
      )
    end
  end
end
