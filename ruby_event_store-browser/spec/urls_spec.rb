require "spec_helper"

module RubyEventStore
  module Browser
    RSpec.describe Urls do
      specify do
        expect(Urls.initial).to eq(Urls.initial)
      end

      specify do
        routing = Urls.from_configuration("http://example.com:9393", nil)

        url = routing.paginated_events_from_stream_url(id: "all")

        expect(url).to eq("http://example.com:9393/api/streams/all/relationships/events")
      end

      specify "passing pagination params" do
        routing = Urls.from_configuration("http://example.com:9393", "")

        url = routing.paginated_events_from_stream_url(id: "all", position: "head", direction: "forward", count: 30)

        expect(url).to eq(
          "http://example.com:9393/api/streams/all/relationships/events?page%5Bposition%5D=head&page%5Bdirection%5D=forward&page%5Bcount%5D=30"
        )
      end

      specify "escaping stream name" do
        routing = Urls.from_configuration("http://example.com:9393", "")

        url = routing.paginated_events_from_stream_url(id: "foo/bar.xml")

        expect(url).to eq("http://example.com:9393/api/streams/foo%2Fbar.xml/relationships/events")
      end

      specify "#root_url without additional path" do
        routing = Urls.from_configuration("http://example.com:9393", "")

        expect(routing.app_url).to eq("http://example.com:9393")
      end

      specify "#root_url with additional path" do
        routing = Urls.from_configuration("http://example.com:9393", "/res")

        expect(routing.app_url).to eq("http://example.com:9393/res")
      end

      specify "#streams_url" do
        routing = Urls.from_configuration("http://example.com:9393", "/res")

        expect(routing.streams_url).to eq("http://example.com:9393/res/api/streams")
      end

      specify "#events_url" do
        routing = Urls.from_configuration("http://example.com:9393", "/res")

        expect(routing.events_url).to eq("http://example.com:9393/res/api/events")
      end

      specify "#api_url" do
        routing = Urls.from_configuration("http://example.com:9393", "/res")

        expect(routing.api_url).to eq("http://example.com:9393/res/api")
      end

      specify "#browser_js_url" do
        routing = Urls.from_configuration("http://example.com:9393", "/res")
        expect(routing.browser_js_url).to eq("http://example.com:9393/res/ruby_event_store_browser.js")
      end

      specify "#bootstrap_js_url" do
        routing = Urls.from_configuration("http://example.com:9393", "/res")
        expect(routing.bootstrap_js_url).to eq("http://example.com:9393/res/bootstrap.js")
      end

      specify "with custom api_url" do
        routing = Urls.from_configuration("http://example.com:9393", "/res", "http://api.example.com")

        expect(routing.api_url).to eq("http://api.example.com")
      end
    end
  end
end
