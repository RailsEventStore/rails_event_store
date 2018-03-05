require "postgresql_queue/version"

module PostgresqlQueue
  class Reader
    def initialize(res)
      @res = res
    end

    def events(after_event_id: :head)
      after_event_id ||= :head
      events = @res.read_all_streams_forward(start: after_event_id, count: 100)
      # visible_since = EventInStream.
      #   where(stream: RubyEventStore::GLOBAL_STREAM).
      #   where(id: events.map(&:event_id))
      #   pluck(:id, :xmin)
      return events
    end
  end
end