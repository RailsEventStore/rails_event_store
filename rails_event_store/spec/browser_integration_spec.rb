# frozen_string_literal: true

require "spec_helper"
require "rails_event_store/middleware"
require "rack/test"
require "rack/lint"
require "support/test_application"

module RailsEventStore
  ::RSpec.describe Browser do
    specify "root" do
      request = ::Rack::MockRequest.new(app)
      response = request.get("/res")

      expect(response.status).to eq(200)
      expect(
        response.body,
      ).to match %r{<script type="text/javascript" src="http://example.org/res/ruby_event_store_browser.js"></script>}
    end

    specify "api" do
      event_store.publish(events = 21.times.map { DummyEvent.new })
      request = ::Rack::MockRequest.new(app)
      response = request.get("/res/api/streams/all/relationships/events")

      expect(JSON.parse(response.body)["links"]).to eq(
        {
          "last" =>
            "http://example.org/res/api/streams/all/relationships/events?page%5Bposition%5D=head&page%5Bdirection%5D=forward&page%5Bcount%5D=20",
          "next" =>
            "http://example.org/res/api/streams/all/relationships/events?page%5Bposition%5D=#{events[1].event_id}&page%5Bdirection%5D=backward&page%5Bcount%5D=20",
        },
      )
    end

    specify "browser present at auto-generated path helper" do
      expect(app_session).to respond_to(:ruby_event_store_browser_app_path)
      expect(app_session.ruby_event_store_browser_app_path).to eq("/res")
    end

    def event_store
      Client.new
    end

    def app
      Rails.application
    end

    def app_session
      session = ActionDispatch::Integration::Session.new(app)
      session.extend(app.routes.url_helpers)
      session.extend(app.routes.mounted_helpers)
      session
    end
  end
end
