# frozen_string_literal: true

require "spec_helper"

module RubyEventStore
  module Browser
    ::RSpec.describe Urls do
      specify do
        initial = Urls.initial
        expect(initial.app_url).to be_nil
      end

      specify { expect(Urls.initial).to eq(Urls.initial) }
      specify { expect(Urls.initial).not_to eq(Object) }

      specify do
        mocked_request = Rack::Request.new(Rack::MockRequest.env_for("http://example.net"))
        with_request = Urls.initial.with_request(mocked_request)

        expect(with_request.app_url).to eq("http://example.net")
      end

      specify do
        mocked_request = Rack::Request.new(Rack::MockRequest.env_for("http://example.net", script_name: "/res"))
        with_request = Urls.initial.with_request(mocked_request)

        expect(with_request.app_url).to eq("http://example.net/res")
      end

      specify do
        mocked_request = Rack::Request.new(Rack::MockRequest.env_for("http://example.net"))
        expect(Urls.initial).not_to eq(Urls.initial.with_request(mocked_request))
      end

      specify do
        mocked_request = Rack::Request.new(Rack::MockRequest.env_for("http://example.net"))
        expect(Urls.initial.with_request(mocked_request)).to eq(Urls.initial.with_request(mocked_request))
      end

      specify do
        from_configuration = Urls.from_configuration("http://example.net", nil)

        expect(from_configuration.app_url).to eq("http://example.net")
      end

      specify do
        from_configuration = Urls.from_configuration("http://example.net", "/res")

        expect(from_configuration.app_url).to eq("http://example.net/res")
      end

      specify do
        expect(Urls.from_configuration("http://example.net", nil)).to eq(
          Urls.from_configuration("http://example.net", nil),
        )
      end

      specify do
        expect(Urls.from_configuration("http://example.net", "/res")).not_to eq(
          Urls.from_configuration("http://example.net", nil),
        )
      end

      specify do
        expect(Urls.from_configuration("http://example.com", nil)).not_to eq(
          Urls.from_configuration("http://example.net", nil),
        )
      end

      specify "stream_url" do
        urls = Urls.from_configuration("http://example.com:9393", "/res")
        expect(urls.stream_url("all")).to eq("http://example.com:9393/res/streams/all")
      end

      specify "stream_url escapes stream name" do
        urls = Urls.from_configuration("http://example.com:9393", nil)
        expect(urls.stream_url("foo/bar.xml")).to eq("http://example.com:9393/streams/foo%2Fbar.xml")
      end

      specify "event_url" do
        urls = Urls.from_configuration("http://example.com:9393", "/res")
        expect(urls.event_url("abc-123")).to eq("http://example.com:9393/res/events/abc-123")
      end

      specify "stream_page_url" do
        urls = Urls.from_configuration("http://example.com:9393", nil)
        cursor = { position: "abc", direction: :backward }
        expect(urls.stream_page_url("all", cursor, 20)).to eq(
          "http://example.com:9393/streams/all?page%5Bposition%5D=abc&page%5Bdirection%5D=backward&page%5Bcount%5D=20",
        )
      end

      specify "swimlane_url" do
        urls = Urls.from_configuration("http://example.com:9393", "/res")
        expect(urls.swimlane_url(%w[fizz buzz])).to eq(
          "http://example.com:9393/res/swimlane?streams%5B%5D=fizz&streams%5B%5D=buzz",
        )
      end

      specify "swimlane_url with sort" do
        urls = Urls.from_configuration("http://example.com:9393", nil)
        expect(urls.swimlane_url(%w[fizz], "as_of")).to eq(
          "http://example.com:9393/swimlane?streams%5B%5D=fizz&sort=as_of",
        )
      end

      specify "swimlane_more_url" do
        urls = Urls.from_configuration("http://example.com:9393", nil)
        expect(urls.swimlane_more_url(%w[fizz buzz], "2024-01-01T12:00:00.000000Z", nil)).to eq(
          "http://example.com:9393/swimlane/more?streams%5B%5D=fizz&streams%5B%5D=buzz&cursor=2024-01-01T12%3A00%3A00.000000Z",
        )
      end

      specify "swimlane_more_url with sort" do
        urls = Urls.from_configuration("http://example.com:9393", nil)
        expect(urls.swimlane_more_url(%w[fizz], "2024-01-01T12:00:00.000000Z", "as_of")).to eq(
          "http://example.com:9393/swimlane/more?streams%5B%5D=fizz&cursor=2024-01-01T12%3A00%3A00.000000Z&sort=as_of",
        )
      end

      specify "app_url_for" do
        urls = Urls.from_configuration("http://example.com:9393", "/res")
        expect(urls.app_url_for("process_managers", "Foo$123")).to eq(
          "http://example.com:9393/res/process_managers/Foo%24123",
        )
      end

      specify "app_url_for escapes each segment separately" do
        urls = Urls.from_configuration("http://example.com:9393", nil)
        expect(urls.app_url_for("nested", "foo/bar.xml")).to eq("http://example.com:9393/nested/foo%2Fbar.xml")
      end

      specify "app_url_for with query" do
        urls = Urls.from_configuration("http://example.com:9393", nil)
        expect(urls.app_url_for("swimlane", query: [["streams[]", "fizz"], ["streams[]", "buzz"]])).to eq(
          "http://example.com:9393/swimlane?streams%5B%5D=fizz&streams%5B%5D=buzz",
        )
      end

      specify "browser_css_url" do
        urls = Urls.from_configuration("http://example.com:9393", "/res")
        expect(urls.browser_css_url).to eq("http://example.com:9393/res/#{BROWSER_CSS}")
      end

      specify "browser_js_url" do
        urls = Urls.from_configuration("http://example.com:9393", "/res")
        expect(urls.browser_js_url).to eq("http://example.com:9393/res/#{BROWSER_JS}")
      end

    end
  end
end
