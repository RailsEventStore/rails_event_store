# frozen_string_literal: true

require "spec_helper"

module RailsEventStore
  ::RSpec.describe HotwireBrowser do
    include HotwireBrowser::IntegrationHelpers

    specify { expect(web_client.get("/")).to be_ok }

    specify { expect(web_client.get("/").content_type).to eq("text/html; charset=utf-8") }

    specify { expect(web_client.post("/")).to be_not_found }
    specify { expect(web_client.get("/streams/all")).to be_ok }

    specify do
      event_store.append(event = DummyEvent.new)
      expect(web_client.get("/events/#{event.event_id}")).to be_ok
    end

    specify do
      response = web_client.get("/events/00000000-0000-0000-0000-000000000000")
      expect(response).to be_not_found
      expect(response.body).to include("There's no event with given ID")
    end
  end
end
