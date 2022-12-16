module Minitest
  module RubyEventStore
    module Assertions
      def assert_dispatched(event_store, expected_events, &block)
        collected_events = collect_events(event_store, &block)

        Array(expected_events).each do |expected|
          assert collected_events.map(&:event_type).include?(expected.to_s), <<~EOM
            Expected 
              #{collected_events}
            to include 
              #{expected}
          EOM
        end
      end

      def assert_not_dispatched(event_store, expected_events, &block)
        collected_events = collect_events(event_store, &block)

        Array(expected_events).each do |expected|
          refute collected_events.map(&:event_type).include?(expected.to_s), <<~EOM
            Expected 
              #{collected_events}
            to NOT include 
              #{expected}
          EOM
        end
      end

      def assert_not_published(event_store, event_type)
        assert_equal 0, event_store.read.of_type(event_type).count, "Expected no event of #{event_type} type"
      end

      def assert_published(event_store, event_type, event_data)
        events = event_store.read.of_type(event_type).to_a
        refute events.empty?, "Expected some events of #{event_type} type, none were there"
        events.each do |e|
          assert_equal event_data.with_indifferent_access, e.data, "Event data mismatch"
        end
      end

      def assert_published_once(event_store, event_type, event_data)
        assert_equal 1, event_store.read.of_type(event_type).count, "Expected only one event of #{event_type} type"
        assert_published(event_store, event_type, event_data)
      end

      def assert_nothing_published(event_store)
        assert_equal 0,
                     event_store.read.count,
                     "Expected no events published"
      end

      private

      def collect_events(event_store, &block)
        collected_events = []
        event_store.within { block.call }.subscribe_to_all_events { |event| collected_events << event }.call
        collected_events
      end
    end
  end
end
