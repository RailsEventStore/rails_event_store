# frozen_string_literal: true

require "spec_helper"

module RubyEventStore
  ::RSpec.describe Browser do
    include Browser::IntegrationHelpers

    specify "links assets locally by default" do
      body = web_client.get("/").body

      expect(body).to include(%(href="/ruby_event_store_browser.css"))
      expect(body).to include(%(src="/browser.js"))
    end

    specify "links assets from the CDN when installed from git" do
      allow(Browser::GemSource).to receive(:new).and_return(
        instance_double(Browser::GemSource, from_git?: true, version: "0123456789ab"),
      )

      body = web_client.get("/").body

      expect(body).to include(%(href="https://cdn.railseventstore.org/0123456789ab/ruby_event_store_browser.css"))
      expect(body).to include(%(src="https://cdn.railseventstore.org/0123456789ab/browser.js"))
    end
  end
end
