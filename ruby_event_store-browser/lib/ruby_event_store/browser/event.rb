module RubyEventStore
  module Browser
    class Event
      attr_reader :event_store, :params
      
      def initialize(event_store:, params:)
        @event_store = event_store
        @params      = params
      end

      def as_json
        {
          data: JsonApiEvent.new(event).to_h
        }
      end

      def event
        @event ||= event_store.read_event(event_id)
      end

      def event_id
        params.fetch(:id)
      end
    end
  end
end