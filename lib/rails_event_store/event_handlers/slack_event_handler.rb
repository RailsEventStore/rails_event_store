require 'net/http'
require 'json'

module RailsEventStore
  module EventHandlers
    class SlackEventHandler < EventHandler
      class HTTPClient
        def post(url, params)
          uri = URI.parse(url)

          req = Net::HTTP::Post.new(uri.request_uri)
          req.set_form_data(params)

          http = Net::HTTP.new(uri.host, uri.port)
          http.use_ssl = true

          http.request(req)
        end
      end

      def initialize(webhook_url)
        @webhook_url = webhook_url
        @http_client = HTTPClient.new
      end

      attr_reader :webhook_url, :http_client

      def handle_event(event)
        event_name = event.event_type
        payload = {
          text: "Event #{event_name} raised.",
          username: "Rails EventStore Bot",
        }

        @http_client.post(@webhook_url, {
          payload: payload.to_json
        })
      end
    end
  end
end
