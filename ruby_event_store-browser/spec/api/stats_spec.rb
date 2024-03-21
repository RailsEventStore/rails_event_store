# frozen_string_literal: true

require "spec_helper"

module RubyEventStore
  ::RSpec.describe Browser do
    include Browser::IntegrationHelpers

    specify "not existing" do
      api_client.get "/api/stats"
      expect(api_client.parsed_body["meta"]).to match({
                                                        "events_in_total" => 0
                                                      })
    end
  end
end
