require "spec_helper"

module RubyEventStore
  ::RSpec.describe Browser do
    include Browser::IntegrationHelpers

    specify "something" do
      event_store.publish(DummyEvent.new, stream_name: "dummy-1")
      event_store.publish(DummyEvent.new, stream_name: "dummy-2")

      api_client.get "/api/search_streams/dum"

      expect(api_client.last_response).to be_ok
      expect(api_client.parsed_body["data"]).to match_array(
        [
          { "id" => "$by_type_DummyEvent", "type" => "streams" },
          { "id" => "dummy-2", "type" => "streams" },
          { "id" => "dummy-1", "type" => "streams" }
        ]
      )

      api_client.get "/api/search_streams/dummy-"

      expect(api_client.last_response).to be_ok
      expect(api_client.parsed_body["data"]).to match_array(
        [{ "id" => "dummy-2", "type" => "streams" }, { "id" => "dummy-1", "type" => "streams" }]
      )
    end
  end
end
