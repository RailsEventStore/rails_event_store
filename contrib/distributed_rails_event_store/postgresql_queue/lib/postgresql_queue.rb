require "postgresql_queue/version"

module PostgresqlQueue
  class Reader
    def initialize(res)
      @res = res
    end

    def events(after_event_id: :head)
      after_event_id ||= :head
      events = @res.read_all_streams_forward(start: after_event_id, count: 100)
      return [] if events.empty?
      sql = RailsEventStoreActiveRecord::EventInStream.
        where(stream: RubyEventStore::GLOBAL_STREAM).
        where(event_id: nothing_or(after_event_id) + events.map(&:event_id)).
        order("id ASC").
        select("id, event_id, xmin, xmax").to_sql
      results = ActiveRecord::Base.connection.execute(sql).each.to_a
      txid_snapshot_xmin = Integer(get_xmin)
      after = if after_event_id == :head
        -1
      else
        results.shift['id']
      end
      after += 1
      last  = results.last

      filtered = results.select do |tuple|
        tuple["xmin"].to_i < txid_snapshot_xmin
      end
      filtered_ids = filtered.map{|tuple| tuple["id"] }

      allowed_event_ids = []
      (after..last['id']).each do |id|
        if filtered_ids.include?(id)
          allowed_event_ids << filtered.find{|tuple| tuple["id"] == id}.fetch("event_id")
        elsif id_in_another_stream?(id)
          next
        elsif id_from_rolledback_transaction?(id)
          next
        else
          break
        end
      end

      events.select{|e| allowed_event_ids.include?(e.event_id) }
    end

    private

    def nothing_or(after_event_id)
      return [] if after_event_id == :head
      [after_event_id]
    end

    def id_from_rolledback_transaction?(id)
      result = false
      ActiveRecord::Base.transaction do
        result = true if try_insert(id) == 1
        raise ActiveRecord::Rollback
      end
      result
    end

    def try_insert(id)
      # TODO: Bring back default value
      ActiveRecord::Base.connection.execute("set statement_timeout to 100")
      ActiveRecord::Base.connection.update("INSERT INTO
     event_store_events_in_streams(id, stream, position, event_id, created_at)
     VALUES(#{id}, 'all', NULL, '#{SecureRandom.uuid}', '2018-03-06 16:33:34')
     ON CONFLICT (id) DO NOTHING
     ")
    rescue ActiveRecord::StatementInvalid => e
      if ongoing_transaction?(e)
        false
      else
        raise
      end
    end

    def ongoing_transaction?(e)
      PG::QueryCanceled === e.cause
    end

    def id_in_another_stream?(id)
      # TODO: Optimize me!
      RailsEventStoreActiveRecord::EventInStream.
        where.not(stream: RubyEventStore::GLOBAL_STREAM).
        where(id: id).exists?
    end

    def get_xmin
      ActiveRecord::Base.connection.execute(xminc).each.first.fetch("txid_snapshot_xmin")
    end

    def xminc
      "SELECT * FROM txid_snapshot_xmin(txid_current_snapshot());"
    end
  end
end