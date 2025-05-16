# frozen_string_literal: true

require "spec_helper"

module RubyEventStore
  ::RSpec.describe Browser do
    include Browser::IntegrationHelpers

    specify "happy path" do
      api_client.get "/api/streams/all"

      expect(api_client.last_response).to be_ok
      expect(api_client.parsed_body["data"]).to eq(
        {
          "id" => "all",
          "type" => "streams",
          "attributes" => {
            "related_streams" => nil,
          },
          "relationships" => {
            "events" => {
              "links" => {
                "self" => "http://www.example.com/api/streams/all/relationships/events",
              },
            },
          },
        },
      )
    end

    specify "fancy stream name" do
      api_client.get "/api/streams/foo%2Fbar.xml"

      expect(api_client.last_response).to be_ok
      expect(api_client.parsed_body["data"]).to eq(
        {
          "id" => "foo/bar.xml",
          "type" => "streams",
          "attributes" => {
            "related_streams" => nil,
          },
          "relationships" => {
            "events" => {
              "links" => {
                "self" => "http://www.example.com/api/streams/foo%2Fbar.xml/relationships/events",
              },
            },
          },
        },
      )
    end
  end
end
