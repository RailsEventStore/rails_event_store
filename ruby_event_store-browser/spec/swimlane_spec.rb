# frozen_string_literal: true

require "spec_helper"
require "json"
require "uri"

module RubyEventStore
  module Browser
    ::RSpec.describe Browser do
      let(:event_store) { RubyEventStore::Client.new }
      let(:app) { App.for(event_store_locator: -> { event_store }) }
      let(:client) { Rack::MockRequest.new(Rack::Lint.new(app)) }
      let(:base_time) { Time.utc(2024, 1, 1, 12, 0, 0) }

      def event_at(time, valid_at: nil)
        DummyEvent.new.tap do |event|
          event.metadata[:timestamp] = time
          event.metadata[:valid_at] = valid_at if valid_at
        end
      end

      def more_url(stream_names, cursor_time, sort = nil)
        pairs = stream_names.map { |name| ["streams[]", name] }
        pairs << ["cursor", cursor_time.iso8601(TIMESTAMP_PRECISION)]
        pairs << ["sort", sort] if sort
        "http://example.org/swimlane/more?#{URI.encode_www_form(pairs)}"
      end

      specify "compare view lists events from all compared streams" do
        event_store.append(e1 = event_at(base_time + 1), stream_name: "fizz")
        event_store.append(e2 = event_at(base_time + 2), stream_name: "buzz")

        response = client.get("/swimlane?streams%5B%5D=fizz&streams%5B%5D=buzz")
        expect(response.status).to eq(200)
        expect(response.headers["content-type"]).to eq("text/html;charset=utf-8")
        expect(response.body).to include("Comparing fizz, buzz")
        expect(response.body).to include(e1.event_id)
        expect(response.body).to include(e2.event_id)
        expect(response.body.scan("<!DOCTYPE").size).to eq(1)
      end

      specify "compare view ignores blank stream params and does not duplicate names" do
        event_store.append(event_at(base_time), stream_name: "fizz")

        body = client.get("/swimlane?streams%5B%5D=fizz&streams%5B%5D=&streams%5B%5D=fizz").body
        expect(body).to include("Comparing fizz</h1>")
      end

      specify "compare view exposes the url for fetching older events" do
        event_store.append(event_at(base_time), stream_name: "buzz")
        events = Array.new(Browser::PAGE_SIZE + 1) { |i| event_at(base_time + i + 1) }
        event_store.append(events, stream_name: "fizz")

        body = client.get("/swimlane?streams%5B%5D=fizz&streams%5B%5D=buzz").body
        expect(body).to include(
          "data-swimlane-more-url-value=\"#{more_url(%w[fizz buzz], base_time + 2)}\"",
        )
      end

      specify "compare view has no more-url when everything fits one page" do
        event_store.append(event_at(base_time), stream_name: "fizz")

        expect(client.get("/swimlane?streams%5B%5D=fizz").body).to include(%q[data-swimlane-more-url-value=""])
      end

      specify "compare more endpoint returns next rows and cursor as JSON" do
        event_store.append(event_at(base_time), stream_name: "buzz")
        events = Array.new(Browser::PAGE_SIZE + 1) { |i| event_at(base_time + i + 1) }
        event_store.append(events, stream_name: "fizz")

        response = client.get("/swimlane/more?streams%5B%5D=fizz&streams%5B%5D=buzz")
        expect(response.status).to eq(200)
        expect(response.headers["content-type"]).to eq("application/json")
        payload = JSON.parse(response.body)
        expect(payload.keys).to eq(%w[html more_url])
        expect(payload["html"]).to include(events.last.event_id)
        expect(payload["html"]).not_to include("<!DOCTYPE")
        expect(payload["more_url"]).to eq(more_url(%w[fizz buzz], base_time + 2))
      end

      specify "compare more endpoint renders a column per requested stream" do
        event_store.append(event_at(base_time), stream_name: "fizz")
        event_store.append(event_at(base_time + 1), stream_name: "buzz")

        payload = JSON.parse(client.get("/swimlane/more?streams%5B%5D=fizz&streams%5B%5D=buzz").body)
        expect(payload["html"].scan("<td").size).to eq(6)
      end

      specify "compare more endpoint tolerates missing streams param" do
        response = client.get("/swimlane/more")
        expect(response.status).to eq(200)
        expect(JSON.parse(response.body)).to eq({ "html" => "", "more_url" => nil })
      end

      specify "compare more endpoint pages from the cursor" do
        e1, e2, e3 = Array.new(3) { |i| event_at(base_time + i + 1) }
        event_store.append([e1, e2, e3], stream_name: "fizz")

        query = URI.encode_www_form([["streams[]", "fizz"], ["cursor", (base_time + 2).iso8601(TIMESTAMP_PRECISION)]])
        payload = JSON.parse(client.get("/swimlane/more?#{query}").body)
        expect(payload["html"]).to include(e1.event_id)
        expect(payload["html"]).not_to include(e2.event_id)
        expect(payload["html"]).not_to include(e3.event_id)
        expect(payload["more_url"]).to be_nil
      end

      specify "compare view sorts by validity time when requested" do
        event_store.append(e1 = event_at(base_time + 2, valid_at: base_time + 11), stream_name: "fizz")
        event_store.append(e2 = event_at(base_time + 1, valid_at: base_time + 12), stream_name: "buzz")

        by_append = client.get("/swimlane?streams%5B%5D=fizz&streams%5B%5D=buzz").body
        expect(by_append.index(e1.event_id)).to be < by_append.index(e2.event_id)
        expect(by_append).to include("/swimlane?streams%5B%5D=fizz&amp;streams%5B%5D=buzz&amp;sort=as_of").or include(
          "/swimlane?streams%5B%5D=fizz&streams%5B%5D=buzz&sort=as_of",
        )

        by_validity = client.get("/swimlane?streams%5B%5D=fizz&streams%5B%5D=buzz&sort=as_of").body
        expect(by_validity.index(e2.event_id)).to be < by_validity.index(e1.event_id)
        expect(by_validity).to include((base_time + 12).utc.iso8601(6))
      end

      specify "compare more endpoint honors as_of sort and carries it in more_url" do
        events = Array.new(Browser::PAGE_SIZE + 1) { |i| event_at(base_time + i, valid_at: base_time + 100 - i) }
        event_store.append(events, stream_name: "fizz")

        query = URI.encode_www_form([["streams[]", "fizz"], ["sort", "as_of"]])
        payload = JSON.parse(client.get("/swimlane/more?#{query}").body)
        expect(payload["html"]).to include(events[0].event_id)
        expect(payload["html"]).to include((base_time + 100).utc.iso8601(6))
        expect(payload["html"]).not_to include(events[20].event_id)
        expect(payload["more_url"]).to eq(more_url(%w[fizz], base_time + 81, "as_of"))
      end

      specify "unknown sort values fall back to created-at order" do
        event_store.append(e1 = event_at(base_time + 2, valid_at: base_time + 11), stream_name: "fizz")
        event_store.append(e2 = event_at(base_time + 1, valid_at: base_time + 12), stream_name: "buzz")

        body = client.get("/swimlane?streams%5B%5D=fizz&streams%5B%5D=buzz&sort=wrong").body
        expect(body.index(e1.event_id)).to be < body.index(e2.event_id)

        query = URI.encode_www_form([["streams[]", "fizz"], ["streams[]", "buzz"], ["sort", "wrong"]])
        html = JSON.parse(client.get("/swimlane/more?#{query}").body).fetch("html")
        expect(html.index(e1.event_id)).to be < html.index(e2.event_id)
      end

      specify "compare endpoints tolerate valueless stream params" do
        event_store.append(event_at(base_time), stream_name: "fizz")

        expect(client.get("/swimlane?streams%5B%5D").body).to include("Comparing </h1>")
        expect(JSON.parse(client.get("/swimlane/more?streams%5B%5D").body)).to eq({ "html" => "", "more_url" => nil })
      end

      specify "compare view carries as_of sort in the url for fetching older events" do
        events = Array.new(Browser::PAGE_SIZE + 1) { |i| event_at(base_time + i, valid_at: base_time + 100 - i) }
        event_store.append(events, stream_name: "fizz")

        body = client.get("/swimlane?streams%5B%5D=fizz&sort=as_of").body
        expect(body).to include("data-swimlane-more-url-value=\"#{more_url(%w[fizz], base_time + 81, "as_of")}\"")
      end

      specify "compare view shows a notice instead of a column for a stream without events" do
        event_store.append(e1 = event_at(base_time), stream_name: "fizz")

        body = client.get("/swimlane?streams%5B%5D=fizz&streams%5B%5D=ghost").body
        expect(body).to include("Comparing fizz</h1>")
        expect(body).to include(%q[Stream <span class="font-bold">ghost</span> does not exist.])
        expect(body).to include(e1.event_id)
        expect(body.scan("<th ").size).to eq(2)
      end

      specify "compare view with only missing streams renders no table" do
        body = client.get("/swimlane?streams%5B%5D=ghost").body
        expect(body).to include(%q[Stream <span class="font-bold">ghost</span> does not exist.])
        expect(body).not_to include("<table")
        expect(body).not_to include("Sort by")
      end

      specify "compare view escapes the missing stream name in the notice" do
        body = client.get("/swimlane?streams%5B%5D=%3Cscript%3E").body
        expect(body).to include("&lt;script&gt;")
        expect(body).not_to include("<script>")
      end

      specify "compare view leaves missing streams out of the base url for adding streams" do
        event_store.append(event_at(base_time), stream_name: "fizz")

        body = client.get("/swimlane?streams%5B%5D=fizz&streams%5B%5D=ghost&sort=as_of").body
        expect(body).to include(
          %q[data-swimlane-add-base-url-value="http://example.org/swimlane?streams%5B%5D=fizz&sort=as_of"],
        )
      end

      specify "compare view leaves missing streams out of the url for fetching older events" do
        events = Array.new(Browser::PAGE_SIZE + 1) { |i| event_at(base_time + i + 1) }
        event_store.append(events, stream_name: "fizz")

        body = client.get("/swimlane?streams%5B%5D=fizz&streams%5B%5D=ghost").body
        expect(body).to include("data-swimlane-more-url-value=\"#{more_url(%w[fizz], base_time + 2)}\"")
      end

      specify "comparing the all stream shows the global timeline" do
        event_store.append(event = event_at(base_time), stream_name: "orders")

        body = client.get("/swimlane?streams%5B%5D=all").body
        expect(body).to include(event.event_id)
      end

      specify "comparing the all stream on an empty event store is not reported as missing" do
        body = client.get("/swimlane?streams%5B%5D=all").body
        expect(body).to include("Comparing all</h1>")
        expect(body).not_to include("does not exist")
      end

      specify "stream page links to comparing that stream" do
        event_store.append(event_at(base_time), stream_name: "fizz")

        body = client.get("/streams/fizz").body
        expect(body).to include("Swimlane view")
        expect(body).to include("http://example.org/swimlane?streams%5B%5D=fizz")
      end

      specify "the global stream page does not link to the swimlane view" do
        event_store.append(event_at(base_time), stream_name: "fizz")

        expect(client.get("/streams/all").body).not_to include("Swimlane view")
      end

      specify "removing a stream from comparison keeps the sort" do
        event_store.append(event_at(base_time), stream_name: "fizz")
        event_store.append(event_at(base_time + 1), stream_name: "buzz")

        body = client.get("/swimlane?streams%5B%5D=fizz&streams%5B%5D=buzz&sort=as_of").body
        expect(body).to include("/swimlane?streams%5B%5D=buzz&amp;sort=as_of").or include(
          "/swimlane?streams%5B%5D=buzz&sort=as_of",
        )
      end
    end
  end
end
