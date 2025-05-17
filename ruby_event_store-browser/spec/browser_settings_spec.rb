# frozen_string_literal: true

require "spec_helper"

module RubyEventStore
  ::RSpec.describe Browser do
    nested_app = ->(app) { Rack::Builder.new { map("/res") { run(app) } } }
    include Browser::IntegrationHelpers.with(host: "railseventstore.org", app: nested_app)

    specify "passes RES version" do
      response = web_client.get "/res"

      expect(parsed_meta_content(response.body)["resVersion"]).to eq(RubyEventStore::VERSION)
    end

    specify "passes root_url" do
      response = web_client.get "/res"

      expect(parsed_meta_content(response.body)["rootUrl"]).to eq("http://railseventstore.org/res")
    end

    specify "builds api_url based on the settings" do
      inside_app =
        Browser::App.for(event_store_locator: -> { event_store }, api_url: "https://example.com/some/custom/api/url")
      outside_app =
        Rack::Builder.new do
          map "/res" do
            run inside_app
          end
        end

      response = WebClient.new(outside_app, "railseventstore.org").get("/res")

      expect(parsed_meta_content(response.body)["apiUrl"]).to eq("https://example.com/some/custom/api/url")
    end

    specify "default api_url is based on root_path" do
      response = web_client.get "/res"

      expect(parsed_meta_content(response.body)["apiUrl"]).to eq("http://railseventstore.org/res/api")
    end

    specify "default JS sources are based on app_url" do
      response = web_client.get "/res"

      script_tags(response.body).each do |script|
        expect(script.attribute("src").value).to match %r{\Ahttp://railseventstore.org/res}
      end

      expect(parsed_meta_content(response.body)["apiUrl"]).to eq("http://railseventstore.org/res/api")
    end

    specify "default CSS sources are based on app_url" do
      response = web_client.get "/res"

      link_tags(response.body).each do |link|
        expect(link.attribute("href").value).to match %r{\Ahttp://railseventstore.org/res}
      end

      expect(parsed_meta_content(response.body)["apiUrl"]).to eq("http://railseventstore.org/res/api")
    end

    def script_tags(response_body)
      Nokogiri.HTML(response_body).css("script")
    end

    def link_tags(response_body)
      Nokogiri.HTML(response_body).css("link[rel=stylesheet]")
    end

    def meta_content(response_body)
      Nokogiri.HTML(response_body).css("meta[name='ruby-event-store-browser-settings']").attribute("content")
    end

    def parsed_meta_content(response_body)
      JSON.parse(meta_content(response_body))
    end
  end
end
