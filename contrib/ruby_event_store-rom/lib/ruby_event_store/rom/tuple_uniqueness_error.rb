# frozen_string_literal: true

module RubyEventStore
  module ROM
    class TupleUniquenessError < StandardError
      class << self
        def for_event_id(event_id)
          new "Uniquness violated for event_id (#{event_id.inspect})"
        end

        def for_stream_and_event_id(stream_name, event_id)
          new "Uniquness violated for stream (#{stream_name.inspect}) and event_id (#{event_id.inspect})"
        end

        def for_stream_and_position(stream_name, position)
          new "Uniquness violated for stream (#{stream_name.inspect}) and position (#{position})"
        end
      end
    end
  end
end
