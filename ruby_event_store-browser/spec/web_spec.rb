# frozen_string_literal: true

require "spec_helper"
require "tmpdir"

module RubyEventStore
  ::RSpec.describe Browser do
    include Browser::IntegrationHelpers

    specify { expect(web_client.get("/")).to be_redirect }

    specify do
      response = web_client.get("/")
      expect(response.location).to end_with("/streams/all")
      expect(response.body).to eq("")
    end

    specify { expect(web_client.get("/streams/all")).to be_ok }

    specify { expect(web_client.get("/streams/all").content_type).to eq("text/html;charset=utf-8") }

    specify do
      event_store.append(DummyEvent.new, stream_name: "test-stream")
      expect(web_client.get("/streams/test-stream").body).to include("Events in test-stream")
    end

    specify do
      event_store.append(event = DummyEvent.new)
      expect(web_client.get("/streams/all").body).to include(event.event_id)
    end

    specify do
      response = web_client.post("/")
      expect(response).to be_not_found
      expect(response.body).to eq("")
    end

    specify do
      event_store.append(event = DummyEvent.new)
      expect(web_client.get("/events/#{event.event_id}")).to be_ok
    end

    specify do
      event_store.append(event = DummyEvent.new)
      response = web_client.get("/events/#{event.event_id}")
      expect(response.body).to include(event.event_id)
      expect(response.body).to include(event.metadata[:timestamp].iso8601(RubyEventStore::TIMESTAMP_PRECISION))
      expect(response.body).to include("valid_at")
    end

    specify "event page lists streams the event belongs to" do
      event_store.append(event = DummyEvent.new, stream_name: "my-stream")
      expect(web_client.get("/events/#{event.event_id}").body).to include("my-stream")
    end

    specify "pagination links contain stream name, position and count" do
      event_store.append(Array.new(Browser::PAGE_SIZE + 1) { DummyEvent.new }, stream_name: "my-stream")
      body = web_client.get("/streams/my-stream").body
      expect(body).to include("streams/my-stream?page%5Bposition%5D")
      expect(body).to include("page%5Bcount%5D=#{Browser::PAGE_SIZE}")
    end

    specify "uses page count param from query string" do
      e1 = DummyEvent.new
      e2 = DummyEvent.new
      event_store.append([e1, e2])

      body = web_client.get("/streams/all?page%5Bcount%5D=1").body
      expect(body).to include(e2.event_id)
      expect(body).not_to include(e1.event_id)
    end

    specify "event page links to parent event via causation_id" do
      parent = DummyEvent.new
      child = DummyEvent.new(metadata: { causation_id: parent.event_id })
      event_store.append([parent, child])
      body = web_client.get("/events/#{child.event_id}").body
      expect(body).to include("Parent event:")
      expect(body).to include(parent.event_id)
    end

    specify "event page lists events caused by this event" do
      parent = DummyEvent.new
      child = DummyEvent.new
      event_store.append([parent, child])
      event_store.link([child.event_id], stream_name: "$by_causation_id_#{parent.event_id}")
      body = web_client.get("/events/#{parent.event_id}").body
      expect(body).to include(child.event_id)
    end

    specify "event page caused_by shows only directly caused events" do
      parent = DummyEvent.new
      child = DummyEvent.new
      unrelated = DummyEvent.new
      event_store.append([parent, child, unrelated])
      event_store.link([child.event_id], stream_name: "$by_causation_id_#{parent.event_id}")
      body = web_client.get("/events/#{parent.event_id}").body
      expect(body).to include(child.event_id)
      expect(body).not_to include(unrelated.event_id)
    end

    specify "event page lists streams in sorted order" do
      event = DummyEvent.new
      event_store.append(event, stream_name: "z-first")
      event_store.link(event.event_id, stream_name: "a-second")
      body = web_client.get("/events/#{event.event_id}").body
      expect(body.index("a-second")).to be < body.index("z-first")
    end

    specify "event page caused_by lists most recent caused events first" do
      parent = DummyEvent.new
      first_child = DummyEvent.new
      second_child = DummyEvent.new
      event_store.append([parent, first_child, second_child])
      event_store.link([first_child.event_id], stream_name: "$by_causation_id_#{parent.event_id}")
      event_store.link([second_child.event_id], stream_name: "$by_causation_id_#{parent.event_id}")
      body = web_client.get("/events/#{parent.event_id}").body
      expect(body.index(second_child.event_id)).to be < body.index(first_child.event_id)
    end

    specify "event page caused_by is limited to PAGE_SIZE" do
      parent = DummyEvent.new
      children = Array.new(Browser::PAGE_SIZE + 1) { DummyEvent.new }
      event_store.append([parent, *children])
      children.each { |c| event_store.link([c.event_id], stream_name: "$by_causation_id_#{parent.event_id}") }
      body = web_client.get("/events/#{parent.event_id}").body
      expect(body).to include("results may be truncated")
    end

    specify "not found page uses absolute url from request for assets" do
      response = web_client.get("/events/00000000-0000-0000-0000-000000000000")
      expect(response.body).to include("http://www.example.com")
    end

    specify "related_streams_query is called with the stream name" do
      called_with = []
      app =
        Browser::App.for(
          event_store_locator: -> { event_store },
          related_streams_query: ->(name) { called_with << name; [] },
        )
      Rack::MockRequest.new(app).get("/streams/my-stream")
      expect(called_with).to include("my-stream")
    end

    specify do
      response = web_client.get("/events/00000000-0000-0000-0000-000000000000")
      expect(response).to be_not_found
      expect(response.content_type).to eq("text/html;charset=utf-8")
      expect(response.body).to include("There's no event with given ID")
      expect(response.body.scan("<!DOCTYPE").size).to eq(1)
    end

    specify "extensions can register their own routes" do
      extension =
        Class.new do
          def register_routes(router, context)
            router.add_route("GET", "/custom") do |_, _|
              [200, { "content-type" => "text/plain" }, ["events: #{context.event_store.read.count}"]]
            end
          end
        end.new
      app = Browser::App.for(event_store_locator: -> { event_store }, extensions: [extension])
      event_store.append(DummyEvent.new)

      response = Rack::MockRequest.new(app).get("/custom")
      expect(response.status).to eq(200)
      expect(response.body).to eq("events: 1")
    end

    specify "extensions can contribute links on the stream page" do
      extension =
        Class.new do
          def register_routes(router, context)
          end

          def stream_links(stream_name, urls)
            return [] unless stream_name.eql?("special")
            [{ label: "Inspect stream", url: "#{urls.app_url}/inspect/#{stream_name}" }]
          end
        end.new
      app = Browser::App.for(event_store_locator: -> { event_store }, extensions: [extension])

      expect(Rack::MockRequest.new(app).get("/streams/special").body).to include("Inspect stream")
      expect(Rack::MockRequest.new(app).get("/streams/other").body).not_to include("Inspect stream")
    end

    specify "extensions can contribute stylesheets to the layout" do
      extension =
        Class.new do
          def register_routes(router, context)
          end

          def stylesheets(urls)
            ["#{urls.app_url}/extension.css"]
          end
        end.new
      app = Browser::App.for(event_store_locator: -> { event_store }, extensions: [extension])

      response = Rack::MockRequest.new(app).get("/streams/all")
      expect(response.status).to eq(200)
      expect(response.body).to include('href="http://example.org/extension.css"')
    end

    specify "extension stylesheets are linked on the not found page" do
      extension =
        Class.new do
          def register_routes(router, context)
          end

          def stylesheets(urls)
            ["#{urls.app_url}/extension.css"]
          end
        end.new
      app = Browser::App.for(event_store_locator: -> { event_store }, extensions: [extension])

      response = Rack::MockRequest.new(app).get("/events/00000000-0000-0000-0000-000000000000")
      expect(response).to be_not_found
      expect(response.body).to include('href="http://example.org/extension.css"')
    end

    specify "extensions can contribute scripts to the layout" do
      extension =
        Class.new do
          def register_routes(router, context)
          end

          def scripts(urls)
            ["#{urls.app_url}/extension.js"]
          end
        end.new
      app = Browser::App.for(event_store_locator: -> { event_store }, extensions: [extension])

      response = Rack::MockRequest.new(app).get("/streams/all")
      expect(response.status).to eq(200)
      expect(response.body).to include('<script type="module" src="http://example.org/extension.js"></script>')
    end

    specify "extension scripts are linked on the not found page" do
      extension =
        Class.new do
          def register_routes(router, context)
          end

          def scripts(urls)
            ["#{urls.app_url}/extension.js"]
          end
        end.new
      app = Browser::App.for(event_store_locator: -> { event_store }, extensions: [extension])

      response = Rack::MockRequest.new(app).get("/events/00000000-0000-0000-0000-000000000000")
      expect(response).to be_not_found
      expect(response.body).to include('<script type="module" src="http://example.org/extension.js"></script>')
    end

    specify "extension can respond with json" do
      extension =
        Class.new do
          def register_routes(router, context)
            router.add_route("GET", "/custom.json") do |_, _|
              context.json(events: context.event_store.read.count, more_url: nil)
            end
          end
        end.new
      app = Browser::App.for(event_store_locator: -> { event_store }, extensions: [extension])
      event_store.append(DummyEvent.new)

      response = Rack::MockRequest.new(app).get("/custom.json")
      expect(response.status).to eq(200)
      expect(response.headers["content-type"]).to eq("application/json")
      expect(JSON.parse(response.body)).to eq({ "events" => 1, "more_url" => nil })
    end

    specify "extension can render a bare partial without the layout" do
      Dir.mktmpdir do |views_root|
        File.write(
          File.join(views_root, "_row.html.erb"),
          "<tr><td><%= h(name) %> at <%= urls.app_url %></td>" \
            "<td><%= render(\"_timestamp\", title: \"Created at\", time: Time.utc(2024, 1, 1), top: true) %></td></tr>",
        )
        extension =
          Class.new do
            def initialize(views_root)
              @views_root = views_root
            end

            def register_routes(router, context)
              views_root = @views_root
              router.add_route("GET", "/rows.json") do |_, urls|
                context.json(html: context.render_partial("_row", views_root: views_root, urls: urls, name: "<x>"))
              end
            end
          end.new(views_root)
        app = Browser::App.for(event_store_locator: -> { event_store }, extensions: [extension])

        response = WebClient.new(app, "example.org").get("/rows.json")
        expect(response.status).to eq(200)
        html = JSON.parse(response.body).fetch("html")
        expect(html).to include("<tr><td>&lt;x&gt; at http://example.org</td>")
        expect(html).to include("Created at")
        expect(html).not_to include("<!DOCTYPE")
      end
    end

    specify "extension can render its own views wrapped in the layout" do
      Dir.mktmpdir do |views_root|
        File.write(File.join(views_root, "hello.html.erb"), "<p>hello <%= h(name) %> from <%= urls.app_url %></p>")
        extension =
          Class.new do
            def initialize(views_root)
              @views_root = views_root
            end

            def register_routes(router, context)
              views_root = @views_root
              router.add_route("GET", "/hello") do |_, urls|
                context.render("hello", views_root: views_root, urls: urls, name: "world")
              end
            end

            def stylesheets(urls)
              ["#{urls.app_url}/extension.css"]
            end

            def scripts(urls)
              ["#{urls.app_url}/extension.js"]
            end
          end.new(views_root)
        app = Browser::App.for(event_store_locator: -> { event_store }, extensions: [extension])

        response = WebClient.new(app, "example.org").get("/hello")
        expect(response.status).to eq(200)
        expect(response.content_type).to eq("text/html;charset=utf-8")
        expect(response.body).to include("<p>hello world from http://example.org</p>")
        expect(response.body.scan("<!DOCTYPE").size).to eq(1)
        expect(response.body).to include('href="http://example.org/extension.css"')
        expect(response.body).to include('<script type="module" src="http://example.org/extension.js"></script>')
      end
    end

    specify "extensions without optional hooks leave pages untouched" do
      bare_extension =
        Class.new do
          def register_routes(router, context)
          end
        end.new
      linking_extension =
        Class.new do
          def register_routes(router, context)
          end

          def stream_links(stream_name, urls)
            [{ label: "Inspect stream", url: "#{urls.app_url}/inspect/#{stream_name}" }]
          end
        end.new
      app = Browser::App.for(event_store_locator: -> { event_store }, extensions: [bare_extension, linking_extension])

      response = Rack::MockRequest.new(app).get("/streams/special")
      expect(response.status).to eq(200)
      expect(response.body).to include("Inspect stream")
      expect(response.body).not_to include('href=""')
    end

    specify "uses configured host for generated URLs" do
      app =
        Browser::App.new(
          event_store_locator: -> { event_store },
          related_streams_query: Browser::DEFAULT_RELATED_STREAMS_QUERY,
          host: "http://configured.example.com",
          root_path: nil,
        )
      env = Rack::MockRequest.env_for("http://other.example.com/")
      status, headers, = app.call(env)
      expect(status).to eq(302)
      expect(headers["location"]).to include("configured.example.com")
    end
  end
end
