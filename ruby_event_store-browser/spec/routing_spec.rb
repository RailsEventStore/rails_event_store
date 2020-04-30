require "spec_helper"

module RubyEventStore
  module Browser
    RSpec.describe Routing do
      specify do
        routing = Routing.new("http://example.com:9393", nil)

        url = routing.paginated_events_from_stream_url(id: "all")

        expect(url).to eq("http://example.com:9393/api/streams/all/relationships/events")
      end

      specify do
        routing = Routing.new("http://example.com:9393", "")

        url = routing.paginated_events_from_stream_url(id: "all", position: "forward")

        expect(url).to eq("http://example.com:9393/api/streams/all/relationships/events/forward")
      end

      specify "escaping stream name" do
        routing = Routing.new("http://example.com:9393", "")

        url = routing.paginated_events_from_stream_url(id: "foo/bar.xml")

        expect(url).to eq("http://example.com:9393/api/streams/foo%2Fbar.xml/relationships/events")
      end
    end
  end
end
