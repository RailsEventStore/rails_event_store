require "postgresql_queue/version"

module PostgresqlQueue
  class Reader
    def initialize(res)
      @res = res
    end

    def events(after_event_id: :head)
      after_event_id ||= :head
      events = @res.read_all_streams_forward(start: after_event_id, count: 100)
      sql = RailsEventStoreActiveRecord::EventInStream.
        where(stream: RubyEventStore::GLOBAL_STREAM).
        where(event_id: events.map(&:event_id)).
        order("id ASC").
        select("id, event_id, xmin").to_sql
      results = ActiveRecord::Base.connection.execute(sql).each.to_a
      txid_snapshot_xmin = Integer(get_xmin)

      event_ids = results.select do |tuple|
        tuple["xmin"].to_i < txid_snapshot_xmin
      end.map{|tuple| tuple["event_id"] }.to_set

      events.select{|e| event_ids.include?(e.event_id) }
    end

    private

    def get_xmin
      ActiveRecord::Base.connection.execute(xminc).each.first.fetch("txid_snapshot_xmin")
    end

    def xminc
      "SELECT * FROM txid_snapshot_xmin(txid_current_snapshot());"
    end
  end
end