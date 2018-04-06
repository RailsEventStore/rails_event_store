require "postgresql_queue/version"
require "postgresql_queue/distributed_repository"

module PostgresqlQueue
  class Reader
    def initialize(repo)
      @repo = repo
    end

    def events(after_event_id:, count: 100, iterated_stream: RubyEventStore::GLOBAL_STREAM)
      events = @repo.read_all_streams_forward(after_event_id || :head, count)
      return [] if events.empty?

      after = find_event_in_stream_id_by_event_id(event_id: after_event_id, stream: iterated_stream)
      last_approved = after
      after += 1
      before = find_event_in_stream_id_by_event_id(event_id: events.last.event_id, stream: iterated_stream)

      eis = RailsEventStoreActiveRecord::EventInStream.
        where("id >= #{after} AND id <= #{before}").
        order("id ASC")

      last  = before

      allowed_event_ids = []
      (after..last).each do |id|
        if id == last_approved+1 && found = eis.find{|event_in_stream| event_in_stream.id == id }
          if found.stream == iterated_stream
            allowed_event_ids << found.event_id
          end
          last_approved = id
        elsif id_locked?(id)
          break
        else
          e = RailsEventStoreActiveRecord::EventInStream.where(id: id).first
          if e
            break
            # appeared now, break and retry again from scratch, it will find it now
          else
            # rollback
            last_approved = id
          end
        end
      end

      events.select{|e| allowed_event_ids.include?(e.event_id) }
    end

    private

    def find_event_in_stream_id_by_event_id(event_id:, stream:)
      if event_id.nil?
        0
      else
        ::RailsEventStoreActiveRecord::EventInStream.where(
          stream: stream
        ).where(event_id: event_id).first!.id
      end
    end

    def id_locked?(id)
      s = <<-SQL
      SELECT
        pg_try_advisory_xact_lock_shared(#{id}) as lolck
      SQL
      result = ActiveRecord::Base.
        connection.
        execute(s).
        each.
        to_a.
        first.fetch('lolck')
      !result
    end

  end
end