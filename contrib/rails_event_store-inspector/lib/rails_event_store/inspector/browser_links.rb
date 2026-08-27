# frozen_string_literal: true

require "cgi"

module RailsEventStore
  module Inspector
    class BrowserLinks
      def self.from_rails
        new(discover_root)
      end

      def self.discover_root
        return nil unless defined?(::Rails) && ::Rails.respond_to?(:application) && ::Rails.application

        route =
          ::Rails.application.routes.routes.find do |r|
            r.app.respond_to?(:app) && r.app.app.respond_to?(:name) && r.app.app.name == "RailsEventStore::Browser"
          end
        return nil unless route

        path = route.path.spec.to_s.sub("(.:format)", "")
        path.empty? ? nil : path
      rescue StandardError
        nil
      end

      def initialize(root)
        @root = root
      end

      def event(event_id)
        return nil if event_id.nil?
        build("events", event_id.to_s)
      end

      def by_correlation(correlation_id)
        return nil if correlation_id.nil?
        build("streams", "$by_correlation_id_#{correlation_id}")
      end

      def swimlane(stream_names)
        return nil if @root.nil? || stream_names.empty? || !swimlane_available?

        query = stream_names.map { |name| "streams[]=#{CGI.escape(name)}" }.join("&")
        "#{@root}/swimlane?#{query}"
      end

      def swimlane_available?
        return @swimlane_available if defined?(@swimlane_available)

        @swimlane_available =
          defined?(::RubyEventStore::Browser::Urls) &&
            ::RubyEventStore::Browser::Urls.method_defined?(:swimlane_url)
      end

      private

      def build(segment, value)
        return nil if @root.nil?
        "#{@root}/#{segment}/#{CGI.escape(value)}"
      end
    end
  end
end
