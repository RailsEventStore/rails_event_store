# frozen_string_literal: true

module RubyEventStore
  module Browser
    class ExtensionContext
      attr_reader :event_store

      def initialize(event_store, layout)
        @event_store = event_store
        @layout = layout
      end

      def render(template, urls:, title: nil, **locals)
        @layout.render(template, urls: urls, title: title, **locals)
      end

      def not_found(urls, message: "Page not found")
        @layout.not_found(urls, message: message)
      end
    end
  end
end
