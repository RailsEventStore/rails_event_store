# frozen_string_literal: true

require_relative "panel"

module RailsEventStore
  module Inspector
    class Middleware
      def initialize(app, buffer: Inspector.buffer, configuration: Inspector.configuration)
        @app = app
        @buffer = buffer
        @configuration = configuration
      end

      def call(env)
        Thread.current[Inspector::ACTIVE] = allowed?(env)

        return @app.call(env) unless Inspector.active?

        resolved = scope_for(env)
        Thread.current[Inspector::SCOPE] = resolved.key

        return reset(env) if env["PATH_INFO"] == Inspector::RESET_PATH
        return serve_panel(env) if env["PATH_INFO"] == Inspector::PANEL_PATH

        status, headers, body = @app.call(env)

        return warn_about_compression(status, headers, body) if compressed?(headers)
        return [status, headers, body] unless injectable?(status, headers, body)

        html = body.to_ary.join
        return [status, headers, body] unless html.include?("</body>")

        html = html.sub("</body>", panel(env).to_html + "</body>")
        headers = headers.merge("content-length" => html.bytesize.to_s)
        add_cookie(headers, resolved.set_cookie) if resolved.set_cookie
        [status, headers, [html]]
      ensure
        Thread.current[Inspector::ACTIVE] = nil
        Thread.current[Inspector::SCOPE] = nil
      end

      private

      def allowed?(env)
        @configuration.enabled.call(env) == true
      rescue StandardError
        false
      end

      def serve_panel(env)
        rendered = panel(env)
        headers = { "content-type" => "text/html; charset=utf-8", Inspector::COUNT_HEADER => rendered.event_count.to_s }
        body = count_only?(env) ? "" : rendered.to_fragment

        [200, headers.merge("content-length" => body.bytesize.to_s, "cache-control" => "no-store"), [body]]
      end

      def count_only?(env)
        env["QUERY_STRING"].to_s.split("&").include?("count=1")
      end

      def scope_for(env)
        Scope.new(@configuration.scope).call(env)
      rescue StandardError
        Scope::Resolved.new(:unresolved, nil)
      end

      def add_cookie(headers, cookie)
        key = headers.keys.find { |name| name.downcase == "set-cookie" } || "set-cookie"

        headers[key] =
          case (existing = headers[key])
          when nil then cookie
          when Array then existing + [cookie]
          else [existing, cookie]
          end
      end

      def reset(env)
        scope = Inspector.scope
        @buffer.clear { |entry| entry[:scope] == scope }
        [302, { "location" => env["HTTP_REFERER"] || "/", "content-length" => "0" }, []]
      end

      CSP_NONCE = "action_dispatch.content_security_policy_nonce"

      def panel(env)
        scope = Inspector.scope
        mine = @buffer.to_a.select { |entry| entry[:scope] == scope }

        Panel.new(mine, Inspector.browser_links, nonce: csp_nonce(env))
      end

      def csp_nonce(env)
        return env[CSP_NONCE] if env[CSP_NONCE]
        return nil unless defined?(::ActionDispatch::Request)

        ::ActionDispatch::Request.new(env).content_security_policy_nonce
      rescue StandardError
        nil
      end

      def injectable?(status, headers, body)
        status == 200 && content_type(headers) == "text/html" && body.respond_to?(:to_ary)
      end

      def compressed?(headers)
        encoding = headers.find { |name, _| name.downcase == "content-encoding" }&.last.to_s
        !encoding.empty? && encoding != "identity"
      end

      def warn_about_compression(status, headers, body)
        unless defined?(@warned_about_compression)
          @warned_about_compression = true
          Kernel.warn(
            "[res-inspector] responses arrive compressed, so the panel cannot be attached. " \
              "The middleware sits outside the compressing one; insert it further in.",
          )
        end
        [status, headers, body]
      end

      def content_type(headers)
        headers.find { |name, _| name.downcase == "content-type" }&.last.to_s.split(";").first.to_s.strip
      end
    end
  end
end
