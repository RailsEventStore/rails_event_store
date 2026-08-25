# frozen_string_literal: true

require_relative "panel"

module RailsEventStore
  module Inspector
    class Middleware
      def initialize(app, buffer: Inspector.buffer)
        @app = app
        @buffer = buffer
      end

      def call(env)
        status, headers, body = @app.call(env)
        return [status, headers, body] unless injectable?(status, headers, body)

        html = body.to_ary.join
        return [status, headers, body] unless html.include?("</body>")

        html = html.sub("</body>", panel(env).to_html + "</body>")
        [status, headers.merge("content-length" => html.bytesize.to_s), [html]]
      end

      private

      def panel(env)
        Panel.new(@buffer.to_a, Inspector.browser_links)
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
