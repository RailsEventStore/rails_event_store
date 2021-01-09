module Minitest
  module RubyEventStore
    module Assertions
      def assert_dispatched(event_store, expected_events, &block)
        collected_events = collect_events(event_store, &block)

        Array(expected_events).each do |expected|
          assert collected_events.include?(expected.to_s), "bazinga"
        end
      end

      def assert_not_dispatched(event_store, expected_events, &block)
        collected_events = collect_events(event_store, &block)

        Array(expected_events).each do |expected|
          refute collected_events.include?(expected.to_s), "bazinga"
        end
      end

      private

      def collect_events(event_store, &block)
        collected_events = []
        event_store.within do
          block.call
        end.subscribe_to_all_events do |event|
          collected_events << event.event_type
        end.call
        collected_events
      end
    end
  end
end