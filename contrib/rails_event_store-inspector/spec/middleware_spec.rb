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
