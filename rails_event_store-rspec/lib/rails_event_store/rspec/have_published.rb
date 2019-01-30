module RailsEventStore
  module RSpec
    class HavePublished
      include ::RSpec::Matchers


      def initialize(mandatory_expected, *optional_expected, differ:, phraser:)
        @expected  = simplify_expected([mandatory_expected, *optional_expected])
        @matcher   = ::RSpec::Matchers::BuiltIn::Include.new(*expected)
        @differ    = differ
        @phraser   = phraser
      end

      def matches?(event_store)
        @events = event_store.read
        @events = events.stream(stream_name) if stream_name
        @events = events.from(start)         if start
        @events = simplify_actual(events.each.to_a)
        @matcher.matches?(events) && matches_count?
      end

      def exactly(count)
        @count = count
        self
      end

      def in_stream(stream_name)
        @stream_name = stream_name
        self
      end

      def times
        self
      end
      alias :time :times

      def from(event_id)
        @start = event_id
        self
      end

      def once
        exactly(1)
      end

      def failure_message
        format_output(prepare_diff(expected, events))
      end

      def failure_message_when_negated
        format_negated_output(prepare_diff(expected, events))
      end

      def description
        "have published events: #{expected.map {|e| e[:class]}.join(', ')}"
      end

      def strict
        @matcher = ::RSpec::Matchers::BuiltIn::Match.new(expected)
        self
      end

      private

      def prepare_diff(expected, events)
        all_events = events.clone
        all_events_classes = all_events.map {|e| e[:class]}
        expected.map do |e|
          event = e.clone
          expected_klass_name = event[:class]
          expected_data       = event[:data]
          expected_metadata   = event[:metadata]

          found_event = all_events.find { |element| element[:class] == expected_klass_name }

          if expected_metadata.kind_of?(::RSpec::Matchers::BuiltIn::BeAnInstanceOf)
            event.delete(:metadata)
            found_event.delete(:metadata) if found_event
          end

          if expected_data.kind_of?(::RSpec::Matchers::BuiltIn::BeAnInstanceOf)
            event.delete(:data)
            found_event.delete(:data) if found_event
          end

          differences = found_event ? differ.diff(event.except(:class), found_event.except(:class)) : :event_not_found
          all_events.delete(found_event)
          [expected_klass_name, differences, all_events_classes]
        end
      end

      def format_output(diff)
        diff.map do |event_class, differences, all_events_classes|
          if differences == :event_not_found
            diff = differ.diff(all_events_classes + [event_class], all_events_classes)
            "expected #{event_class} to be published, diff:\n#{diff}"
          elsif differences.present?
            "expected #{event_class} to be published with:\n#{differences}"
          end
        end.join("\n")
      end

      def format_negated_output(diff)
        diff.map do |event_class, differences, all_events_classes|
          if differences != :event_not_found
            diff = differ.diff(all_events_classes - [event_class], all_events_classes)
            "expected #{event_class} not to be published, diff:\n#{diff}"
          else
            ''
          end
        end.join("\n")
      end

      def simplify_expected(input)
        input.map do |e|
          if e.kind_of?(BeEvent)
            klass = e.expected
            data = e.expected_data.nil? ? be_instance_of(Hash) : e.expected_data
            metadata = e.expected_metadata.nil? ? be_instance_of(Hash) : e.expected_metadata
            {class: klass, data: data, metadata: metadata}
          else
            {class: e, data: be_instance_of(Hash), metadata: be_instance_of(Hash)}
          end
        end
      end

      def simplify_actual(input)
        input.to_a.map { |e| {class: e.class, data: e.data.to_h, metadata: e.metadata.to_h} }
      end

      def matches_count?
        return true unless count
        raise NotSupported if expected.size > 1

        expected.all? do |event_or_matcher|
          events.select do |e|
            event_or_matcher[:class] == e[:class]
          end.size.equal?(count)
        end
      end

      attr_reader :differ, :phraser, :stream_name, :expected, :count, :events, :start
    end
  end
end

