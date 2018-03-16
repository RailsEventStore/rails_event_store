require "postgresql_queue/version"
require "postgresql_queue/distributed_repository"

module PostgresqlQueue
  class Reader
    def initialize(res)
      @res = res
    end

    def events(after_event_id: :head)
      after_event_id ||= :head
      events = @res.read_all_streams_forward(start: after_event_id, count: 100)
      return [] if events.empty?
      first_event, last_event = events.first, events.last

      eisids = ::RailsEventStoreActiveRecord::EventInStream.where(
        stream: RubyEventStore::GLOBAL_STREAM
      ).where(event_id: [first_event.event_id, last_event.event_id]).
        order("id ASC").pluck(:id)
      eisid_first, eisid_last = eisids.first, eisids.last
      eisid_first -=1
      eisid_last+=1

      # FIXME!
      # We should get all EventInStream between after..eisid_last
      # instead of eisid_first..eisid_last because there can be
      # another IDs there from other streams and linked events!
      eis = RailsEventStoreActiveRecord::EventInStream.
        where("id >= #{eisid_first} AND id <= #{eisid_last}").
        order("id ASC").to_a
      after = if after_event_id == :head
        0
      else
        ::RailsEventStoreActiveRecord::EventInStream.where(
          stream: RubyEventStore::GLOBAL_STREAM
        ).where(event_id: after_event_id).first!.id
      end
      last_approved = after
      after += 1
      last  = eisid_last

      allowed_event_ids = []
      (after..last).each do |id|
        if id == last_approved+1 && found = eis.find{|event_in_stream| event_in_stream.id == id }
          if found.stream == RubyEventStore::GLOBAL_STREAM
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