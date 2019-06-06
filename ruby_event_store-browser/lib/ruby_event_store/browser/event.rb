module RubyEventStore
  module Browser
    class Event
      attr_reader :event_store, :params, :url_builder

      def initialize(event_store:, params:, url_builder:)
        @event_store = event_store
        @params      = params
        @url_builder = url_builder
      end

      def as_json
        {
          data: JsonApiEvent.new(event, url_builder).to_h,
        }
      end

      def event
        @event ||= event_store.read.event!(event_id)
      end

      def event_id
        params.fetch(:id)
      end
    end
  end
end
