# frozen_string_literal: true

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

      def assert_not_published(event_store, event_type, within_stream: nil, &block)
        assert_equal 0,
                     events_published(event_store, event_type, within_stream, &block).size,
                     "Expected no event of #{event_type} type"
      end

      def assert_published(event_store, event_type, with_data: nil, with_metadata: nil, within_stream: nil, &block)
        events = events_published(event_store, event_type, within_stream, &block)
        refute events.empty?, "Expected some events of #{event_type} type, none were there"
        events.each do |e|
          assert_equal with_data.with_indifferent_access, e.data, "Event data mismatch" if with_data
          if with_metadata
            assert_equal with_metadata.with_indifferent_access,
                         e.metadata.to_h.with_indifferent_access.slice(*with_metadata.keys),
                         "Event metadata mismatch"
          end
        end
      end

      def assert_published_once(event_store, event_type, with_data: nil, with_metadata: nil, within_stream: nil, &block)
        events =
          assert_published(
            event_store,
            event_type,
            with_data: with_data,
            with_metadata: with_metadata,
            within_stream: within_stream,
            &block
          )
        assert_equal 1, events.size, "Expected only one event of #{event_type} type"
      end

      def assert_nothing_published(event_store, &block)
        assert_equal 0, events_published(event_store, nil, nil, &block).size, "Expected no events published"
      end

      def assert_event_in_stream(event_store, event, stream_name)
        assert event_store.read.stream(stream_name).event(event.event_id),
               "Expected event #{event.event_id} in #{stream_name} stream, none was there"
      end

      def assert_event_not_in_stream(event_store, event, stream_name)
        refute event_store.read.stream(stream_name).event(event.event_id),
               "Expected event #{event.event_id} not to be in #{stream_name} stream, but it was there"
      end

      def assert_exact_new_events(event_store, expected_new_events, &block)
        events_so_far = event_store.read.to_a
        block.call
        new_events = (event_store.read.to_a - events_so_far).map(&:class)
        assert_equal(expected_new_events, new_events, "Expected new events weren't found")
      end

      def assert_new_events_include(event_store, expected_events, &block)
        events_so_far = event_store.read.to_a
        block.call
        new_events = (event_store.read.to_a - events_so_far).map(&:class)
        assert((expected_events - new_events).empty?, "Didn't include all of: #{expected_events} in #{new_events}")
      end

      def assert_equal_event(expected, actual, verify_id: false)
        assert_equal expected.event_id, actual.event_id if verify_id
        assert_equal expected.class, actual.class
        assert_equal expected.data, actual.data
      end

      def assert_equal_events(expected, checked, verify_id: false)
        assert_equal expected.size, checked.size
        expected.zip(checked) { |e, c| assert_equal_event(e, c, verify_id: verify_id) }
      end

      private

      def events_published(event_store, event_type, stream, &block)
        query = event_store.read
        query = query.stream(stream) if stream
        query = query.of_type(event_type) if event_type
        if block
          events_before = query.to_a
          block.call
        else
          events_before = []
        end
        events_after = query.to_a
        events_after - events_before
      end

      def collect_events(event_store, &block)
        collected_events = []
        event_store.within { block.call }.subscribe_to_all_events { |event| collected_events << event }.call
        collected_events
      end
    end
  end
end
