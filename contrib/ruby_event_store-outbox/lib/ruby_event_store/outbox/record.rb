# frozen_string_literal: true

require 'active_record'

module RubyEventStore
  module Outbox
    class Record < ::ActiveRecord::Base
      self.primary_key = :id
      self.table_name = 'event_store_outbox'

      def hash_payload
        JSON.parse(payload).deep_symbolize_keys
      end
    end

    class Lock < ::ActiveRecord::Base
      self.primary_key = :split_key
      self.table_name = 'event_store_outbox_locks'

      def self.obtain(split_key, process_uuid, clock:)
        transaction do
          l = lock.find_by(split_key: split_key)
          if l.nil?
            begin
              l = create!(split_key: split_key)
            rescue ActiveRecord::RecordNotUnique
            end
            l = lock.find_by(split_key: split_key)
          end

          return :taken unless l.locked_by.nil?

          l.update!(
            locked_by: process_uuid,
            locked_at: clock.now.utc,
          )
        end
        :ok
      rescue ActiveRecord::Deadlocked
        return :deadlocked
      rescue ActiveRecord::LockWaitTimeout
        return :lock_timeout
      end

      def self.release(split_key, process_uuid)
        Lock.transaction do
          lock = Lock.lock.find_by(split_key: split_key)
          return :not_taken_by_this_process if lock.nil? || lock.locked_by != process_uuid

          lock.update!(locked_by: nil, locked_at: nil)
        end
        :ok
      rescue ActiveRecord::Deadlocked
        return :deadlocked
      rescue ActiveRecord::LockWaitTimeout
        return :lock_timeout
      end
    end
  end
end
