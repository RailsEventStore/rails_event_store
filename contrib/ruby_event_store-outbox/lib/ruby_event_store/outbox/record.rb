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

          return :taken if l.locked_by.present? && l.locked_at > 10.minutes.ago

          l.update!(
            locked_by: process_uuid,
            locked_at: clock.now.utc,
          )
        end
        :ok
      rescue ActiveRecord::Deadlocked
        :deadlocked
      rescue ActiveRecord::LockWaitTimeout
        :lock_timeout
      end

      def self.release(split_key, process_uuid)
        transaction do
          l = lock.find_by(split_key: split_key)
          return :not_taken_by_this_process if l.nil? || l.locked_by != process_uuid

          l.update!(locked_by: nil, locked_at: nil)
        end
        :ok
      rescue ActiveRecord::Deadlocked
        :deadlocked
      rescue ActiveRecord::LockWaitTimeout
        :lock_timeout
      end
    end
  end
end
