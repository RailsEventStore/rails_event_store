require "spec_helper"

module RubyEventStore
  module Browser
    RSpec.describe Routing do
      specify do
        routing = Routing.new("http://example.com:9393", nil)

        url = routing.paginated_events_from_stream_url(id: "all")

        expect(url).to eq("http://example.com:9393/api/streams/all/relationships/events")
      end

      specify "passing pagination params" do
        routing = Routing.new("http://example.com:9393", "")

        url = routing.paginated_events_from_stream_url(id: "all", position: "head", direction: "forward", count: 30)

        expect(url).to eq("http://example.com:9393/api/streams/all/relationships/events?page%5Bposition%5D=head&page%5Bdirection%5D=forward&page%5Bcount%5D=30")
      end

      specify "escaping stream name" do
        routing = Routing.new("http://example.com:9393", "")

        url = routing.paginated_events_from_stream_url(id: "foo/bar.xml")

        expect(url).to eq("http://example.com:9393/api/streams/foo%2Fbar.xml/relationships/events")
      end

      specify "#root_url without additional path" do
        routing = Routing.new("http://example.com:9393", "")

        expect(routing.root_url).to eq("http://example.com:9393")
      end

      specify "#root_url with additional path" do
        routing = Routing.new("http://example.com:9393", "/res")

        expect(routing.root_url).to eq("http://example.com:9393/res")
      end

      specify "#streams_url" do
        routing = Routing.new("http://example.com:9393", "/res")

        expect(routing.streams_url).to eq("http://example.com:9393/res/api/streams")
      end

      specify "#events_url" do
        routing = Routing.new("http://example.com:9393", "/res")

        expect(routing.events_url).to eq("http://example.com:9393/res/api/events")
      end
    end
  end
end
