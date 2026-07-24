# frozen_string_literal: true

require "spec_helper"
require "rails_event_store/middleware"
require "rack/test"
require "rack/lint"
require "support/test_application"

module RailsEventStore
  ::RSpec.describe Browser do
    specify "root redirects to all-stream" do
      request = ::Rack::MockRequest.new(app)
      response = request.get("/res")

      expect(response.status).to eq(302)
      expect(response.headers["location"]).to end_with("/res/streams/all")
    end

    specify "streams page" do
      request = ::Rack::MockRequest.new(app)
      response = request.get("/res/streams/all")

      expect(response.status).to eq(200)
      expect(response.body).to include("http://example.org/res/#{RubyEventStore::Browser::BROWSER_JS}")
    end

    specify "app views override browser views" do
      views_root = Rails.root.join("app/views/ruby_event_store_browser")
      FileUtils.mkdir_p(views_root.join("streams"))
      File.write(views_root.join("streams/show.html.erb"), "<h1>Custom <%= h(stream_name) %></h1>")

      response = ::Rack::MockRequest.new(app).get("/res/streams/all")
      expect(response.status).to eq(200)
      expect(response.body).to include("<h1>Custom all</h1>")
    ensure
      FileUtils.rm_rf(views_root)
      [Rails.root.join("app/views"), Rails.root.join("app")].each do |dir|
        Dir.rmdir(dir)
      rescue SystemCallError
      end
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
