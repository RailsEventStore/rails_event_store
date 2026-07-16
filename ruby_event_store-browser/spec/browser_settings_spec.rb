# frozen_string_literal: true

require "spec_helper"

module RubyEventStore
  ::RSpec.describe Browser do
    nested_app = ->(app) { Rack::Builder.new { map("/res") { run(app) } } }
    include Browser::IntegrationHelpers.with(host: "railseventstore.org", app: nested_app)

    specify "shows RES version in footer" do
      response = web_client.get "/res/streams/all"

      expect(response.body).to include("RubyEventStore v#{RubyEventStore::VERSION}")
    end

    specify "default JS source is based on app_url" do
      response = web_client.get "/res/streams/all"

      script_tags(response.body).each do |script|
        expect(script.attribute("src").value).to match %r{\Ahttp://railseventstore.org/res}
      end
    end

    specify "default CSS source is based on app_url" do
      response = web_client.get "/res/streams/all"

      link_tags(response.body).each do |link|
        expect(link.attribute("href").value).to match %r{\Ahttp://railseventstore.org/res}
      end
    end

    def script_tags(response_body)
      Nokogiri.HTML(response_body).css("script[src]")
    end

    def link_tags(response_body)
      Nokogiri.HTML(response_body).css("link[rel=stylesheet]")
    end
  end
end
