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

        status, headers, body = @app.call(env)

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

      def panel(env)
        scope = Inspector.scope
        mine = @buffer.to_a.select { |entry| entry[:scope] == scope }

        Panel.new(mine, Inspector.browser_links)
      end

      def injectable?(status, headers, body)
        status == 200 && content_type(headers) == "text/html" && body.respond_to?(:to_ary)
      end

      def content_type(headers)
        headers.find { |name, _| name.downcase == "content-type" }&.last.to_s.split(";").first.to_s.strip
      end
    end
  end
end
