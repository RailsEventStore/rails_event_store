# frozen_string_literal: true

module RailsEventStore
  module Inspector
    ::RSpec.describe Middleware do
      let(:buffer) { Buffer.new }
      let(:configuration) { Configuration.new.tap { |c| c.enabled = ->(_env) { true } } }

      def response(
        status: 200,
        content_type: "text/html; charset=utf-8",
        body: ["<html><body>hi</body></html>"],
        headers: {},
        env: {}
      )
        app = ->(_env) { [status, { "content-type" => content_type }.merge(headers), body] }
        Middleware.new(app, buffer: buffer, configuration: configuration).call(env)
      end

      def body_of(result)
        result[2].to_ary.join
      end

      specify "injects the panel into an HTML page" do
        status, _headers, body = response

        expect(status).to eq(200)
        expect(body.to_ary.join).to include(%(id="res-inspector"))
      end

      specify "puts it right before the closing body tag" do
        html = body_of(response)

        expect(html.index(%(id="res-inspector"))).to be < html.index("</body>")
      end

      specify "recalculates content-length, so the page is not truncated" do
        result = response

        expect(result[1]["content-length"]).to eq(body_of(result).bytesize.to_s)
      end

      specify "the badge says how much has been collected" do
        buffer.push(entry(:event, scope: "abc", event_id: "e1", event_type: "Ordering::OrderSubmitted"))

        html = body_of(response(env: { "HTTP_COOKIE" => "res_inspector_id=abc" }))

        expect(html).to include(%(<span id="res-inspector-count">1</span>))
      end

      describe "reset" do
        def reset(env = {})
          app = ->(_e) { raise "the application must not be reached" }
          Middleware
            .new(app, buffer: buffer, configuration: configuration)
            .call({ "PATH_INFO" => Inspector::RESET_PATH, "HTTP_COOKIE" => "res_inspector_id=abc" }.merge(env))
        end

        specify "empties the visitor's history without the application ever seeing the request" do
          buffer.push(entry(:event, scope: "abc", event_id: "e1"))

          reset

          expect(buffer.to_a).to be_empty
        end

        specify "sends the visitor back where they came from" do
          status, headers, _body = reset("HTTP_REFERER" => "/orders")

          expect(status).to eq(302)
          expect(headers["location"]).to eq("/orders")
        end

        specify "falls back to the root when there is no referer" do
          expect(reset[1]["location"]).to eq("/")
        end
      end

      specify "the panel offers the reset" do
        app = ->(_env) { raise "the application must not be reached" }

        _status, _headers, body =
          Middleware.new(app, buffer: buffer, configuration: configuration).call("PATH_INFO" => Inspector::PANEL_PATH)

        expect(body.to_ary.join).to include(%(href="#{Inspector::RESET_PATH}"))
      end

      describe "serving the panel" do
        def fetch_panel(query: nil, cookie: nil)
          env = { "PATH_INFO" => Inspector::PANEL_PATH }
          env["QUERY_STRING"] = query if query
          env["HTTP_COOKIE"] = "res_inspector_id=#{cookie}" if cookie
          app = ->(_env) { raise "the application must not be reached" }
          Middleware.new(app, buffer: buffer, configuration: configuration).call(env)
        end

        specify "answers with the tree, not with a whole page" do
          buffer.push(entry(:event, scope: "abc", event_id: "e1", event_type: "SomeEvent"))

          status, headers, body = fetch_panel(cookie: "abc")

          expect(status).to eq(200)
          expect(headers["content-type"]).to eq("text/html; charset=utf-8")
          expect(body.to_ary.join).to include("SomeEvent")
          expect(body.to_ary.join).not_to include("<script")
        end

        specify "shows only this visitor's events" do
          buffer.push(entry(:event, scope: "abc", event_id: "e1", event_type: "MyEvent"))
          buffer.push(entry(:event, scope: "other", event_id: "e2", event_type: "TheirEvent"))

          html = fetch_panel(cookie: "abc")[2].to_ary.join

          expect(html).to include("MyEvent")
          expect(html).not_to include("TheirEvent")
        end

        specify "carries the count in a header" do
          buffer.push(entry(:event, scope: "abc", event_id: "e1"))
          buffer.push(entry(:handler, scope: "abc", event_id: "e1"))

          _status, headers, _body = fetch_panel(cookie: "abc")

          expect(headers[Inspector::COUNT_HEADER]).to eq("1")
        end

        specify "a closed panel asks for the count alone and gets no tree" do
          buffer.push(entry(:event, scope: "abc", event_id: "e1", event_type: "SomeEvent"))

          _status, headers, body = fetch_panel(query: "count=1", cookie: "abc")

          expect(headers[Inspector::COUNT_HEADER]).to eq("1")
          expect(body.to_ary.join).to be_empty
        end

        specify "is never cached, so the panel does not go stale" do
          expect(fetch_panel[1]["cache-control"]).to eq("no-store")
        end

        specify "is not served when the inspector may not watch this request" do
          configuration.enabled = ->(_env) { false }
          app = ->(_env) { [200, { "content-type" => "text/plain" }, ["application answered"]] }

          _status, _headers, body =
            Middleware.new(app, buffer: buffer, configuration: configuration).call("PATH_INFO" => Inspector::PANEL_PATH)

          expect(body.to_ary.join).to eq("application answered")
        end
      end

      describe "scoping" do
        def visit(cookie: nil)
          env = {}
          env["HTTP_COOKIE"] = "res_inspector_id=#{cookie}" if cookie
          app = ->(_env) { [200, { "content-type" => "text/html" }, ["<html><body>hi</body></html>"]] }
          Middleware.new(app, buffer: buffer, configuration: configuration).call(env)
        end

        specify "a visitor without a cookie is given one" do
          _status, headers, _body = visit

          expect(headers["set-cookie"]).to include("res_inspector_id=")
        end

        specify "a visitor who already has one is not given another" do
          _status, headers, _body = visit(cookie: "abc")

          expect(headers["set-cookie"]).to be_nil
        end

        specify "the application's own cookies survive ours being added" do
          app = ->(_env) { [200, { "content-type" => "text/html", "set-cookie" => "_session=xyz" }, ["<html><body>hi</body></html>"]] }

          _status, headers, _body = Middleware.new(app, buffer: buffer, configuration: configuration).call({})

          expect(Array(headers["set-cookie"]).join("\n")).to include("_session=xyz", "res_inspector_id=")
        end

        specify "the badge counts only what this visitor's requests caused" do
          buffer.push(entry(:event, scope: "abc", event_id: "mine", event_type: "MyEvent"))
          buffer.push(entry(:event, scope: "someone-else", event_id: "theirs", event_type: "TheirEvent"))

          html = visit(cookie: "abc")[2].to_ary.join

          expect(html).to include(%(<span id="res-inspector-count">1</span>))
        end

        specify "the collector is told whose events it is gathering" do
          seen = nil
          app = ->(_env) { seen = Inspector.scope; [200, { "content-type" => "text/html" }, ["<html><body>hi</body></html>"]] }

          Middleware.new(app, buffer: buffer, configuration: configuration).call("HTTP_COOKIE" => "res_inspector_id=abc")

          expect(seen).to eq("abc")
        end

        specify "the scope is cleared afterwards, so a recycled thread does not inherit it" do
          visit(cookie: "abc")

          expect(Inspector.scope).to be_nil
        end

        specify "a configured scope replaces the cookie entirely" do
          configuration.scope = ->(env) { env["user"] }
          app = ->(_env) { [200, { "content-type" => "text/html" }, ["<html><body>hi</body></html>"]] }

          _status, headers, _body = Middleware.new(app, buffer: buffer, configuration: configuration).call("user" => "u1")

          expect(headers["set-cookie"]).to be_nil
        end

        specify "a scope that raises does not fall back to everyone's data" do
          configuration.scope = ->(_env) { raise "badly written scope" }
          buffer.push(entry(:event, scope: "abc", event_id: "theirs", event_type: "TheirEvent"))
          app = ->(_env) { raise "the application must not be reached" }

          _status, _headers, body =
            Middleware.new(app, buffer: buffer, configuration: configuration).call("PATH_INFO" => Inspector::PANEL_PATH)

          expect(body.to_ary.join).not_to include("TheirEvent")
        end

        specify "reset clears only the visitor's own history" do
          buffer.push(entry(:event, scope: "abc", event_id: "mine"))
          buffer.push(entry(:event, scope: "someone-else", event_id: "theirs"))
          app = ->(_env) { raise "the application must not be reached" }

          Middleware
            .new(app, buffer: buffer, configuration: configuration)
            .call("PATH_INFO" => Inspector::RESET_PATH, "HTTP_COOKIE" => "res_inspector_id=abc")

          expect(buffer.to_a.map { |e| e[:event_id] }).to eq(["theirs"])
        end
      end

      describe "when it may not watch this request" do
        let(:configuration) { Configuration.new.tap { |c| c.enabled = ->(_env) { false } } }

        specify "the page comes back untouched" do
          expect(body_of(response)).to eq("<html><body>hi</body></html>")
        end

        specify "the reset endpoint is not served — the application sees the path" do
          app = ->(_env) { [200, { "content-type" => "text/plain" }, ["application answered"]] }

          _status, _headers, body =
            Middleware.new(app, buffer: buffer, configuration: configuration).call("PATH_INFO" => Inspector::RESET_PATH)

          expect(body.to_ary.join).to eq("application answered")
        end

        specify "the collector is told to stay quiet" do
          seen = nil
          app = ->(_env) { seen = Inspector.active?; [200, { "content-type" => "text/html" }, ["<html><body>hi</body></html>"]] }

          Middleware.new(app, buffer: buffer, configuration: configuration).call({})

          expect(seen).to be(false)
        end
      end

      describe "the watching flag" do
        specify "is set while the application runs" do
          seen = nil
          app = ->(_env) { seen = Inspector.active?; [200, { "content-type" => "text/html" }, ["<html><body>hi</body></html>"]] }

          Middleware.new(app, buffer: buffer, configuration: configuration).call({})

          expect(seen).to be(true)
        end

        specify "is cleared afterwards, so a recycled thread does not inherit it" do
          response

          expect(Inspector.active?).to be(false)
        end

        specify "is cleared even when the application raises" do
          app = ->(_env) { raise "boom" }

          expect { Middleware.new(app, buffer: buffer, configuration: configuration).call({}) }.to raise_error("boom")
          expect(Inspector.active?).to be(false)
        end

        specify "a predicate that raises counts as a refusal instead of breaking the page" do
          configuration.enabled = ->(_env) { raise "badly written predicate" }

          expect(body_of(response)).to eq("<html><body>hi</body></html>")
        end
      end

      describe "content security policy" do
        specify "carries over the nonce Rails generated for this request" do
          html = body_of(response(env: { "action_dispatch.content_security_policy_nonce" => "abc123" }))

          expect(html).to include(%(<style id="res-inspector-style" nonce="abc123">))
          expect(html).to include(%(<script nonce="abc123">))
        end

        specify "leaves the tags bare when the application sets no policy" do
          html = body_of(response)

          expect(html).to include(%(<style id="res-inspector-style">))
          expect(html).to include("<script>")
        end

        specify "asks Rails for one when the env does not have it yet" do
          request = double(content_security_policy_nonce: "generated")
          stub_const("ActionDispatch::Request", double(new: request))

          expect(body_of(response)).to include(%(nonce="generated"))
        end

        specify "survives a Rails that cannot answer" do
          stub_const("ActionDispatch::Request", double).tap { |d| allow(d).to receive(:new).and_raise("nope") }

          expect(body_of(response)).to include("res-inspector")
        end
      end

      describe "an already compressed response" do
        let(:compressed) { response(headers: { "content-encoding" => "gzip" }, body: ["\x1f\x8bcompressed"]) }

        specify "is handed back untouched rather than corrupted" do
          expect(body_of(compressed)).to eq("\x1f\x8bcompressed")
        end

        specify "says out loud that the panel could not be attached" do
          expect { compressed }.to output(/arrive compressed/).to_stderr
        end

        specify "an identity encoding is not treated as compression" do
          expect(body_of(response(headers: { "content-encoding" => "identity" }))).to include("res-inspector")
        end
      end

      describe "what it will not touch" do
        specify "a page without a closing body tag" do
          expect(body_of(response(body: ["just a fragment"]))).to eq("just a fragment")
        end

        specify "JSON" do
          expect(body_of(response(content_type: "application/json", body: [%({"a":1})]))).to eq(%({"a":1}))
        end

        specify "turbo streams" do
          turbo = %(<turbo-stream action="update" target="x"><template>hi</template></turbo-stream>)

          expect(body_of(response(content_type: "text/vnd.turbo-stream.html", body: [turbo]))).to eq(turbo)
        end

        specify "redirects" do
          expect(body_of(response(status: 302, body: [""]))).to eq("")
        end

        specify "error pages" do
          expect(body_of(response(status: 404))).not_to include("res-inspector")
        end

        specify "a streamed response" do
          streamed =
            Class.new do
              def each
                yield "<html><body>hi</body></html>"
              end
            end.new
          app = ->(_env) { [200, { "content-type" => "text/html" }, streamed] }

          _status, _headers, body = Middleware.new(app, buffer: buffer, configuration: configuration).call({})

          expect(body).to be(streamed)
        end
      end
    end
  end
end
