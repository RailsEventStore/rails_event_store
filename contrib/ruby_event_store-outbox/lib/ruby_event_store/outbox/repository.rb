# frozen_string_literal: true

require 'active_record'

module RubyEventStore
  module Outbox
    class Repository
      def initialize(database_url)
        ActiveRecord::Base.establish_connection(database_url) unless ActiveRecord::Base.connected?
        if ActiveRecord::Base.connection.adapter_name == "Mysql2"
          ActiveRecord::Base.connection.execute("SET SESSION innodb_lock_wait_timeout = 1;")
        end
      end

      def retrieve_batch(fetch_specification, batch_size)
        Record.remaining_for(fetch_specification).order("id ASC").limit(batch_size).to_a
      end

      def get_remaining_count(fetch_specification)
        Record.remaining_for(fetch_specification).count
      end

      def obtain_lock_for_process(fetch_specification, process_uuid, clock:)
        Lock.obtain(fetch_specification, process_uuid, clock: clock)
      end

      def release_lock_for_process(fetch_specification, process_uuid)
        Lock.release(fetch_specification, process_uuid)
      end
    end
  end
end
