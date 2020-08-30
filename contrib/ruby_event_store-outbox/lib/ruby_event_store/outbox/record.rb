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

      def enqueued?
        !enqueued_at.nil?
      end
    end

    class Lock < ::ActiveRecord::Base
      self.primary_key = :split_key
      self.table_name = 'event_store_outbox_locks'

      def self.obtain(message_format, split_key, process_uuid, clock:)
        l = nil
        transaction do
          l = get_lock_record(message_format, split_key)

          return :taken if l.recently_locked?

          l.update!(
            locked_by: process_uuid,
            locked_at: clock.now,
          )
        end
        l
      rescue ActiveRecord::Deadlocked
        :deadlocked
      rescue ActiveRecord::LockWaitTimeout
        :lock_timeout
      end

      def self.release(message_format, split_key, process_uuid)
        transaction do
          l = get_lock_record(message_format, split_key)
          return :not_taken_by_this_process if !l.locked_by?(process_uuid)

          l.update!(locked_by: nil, locked_at: nil)
        end
        :ok
      rescue ActiveRecord::Deadlocked
        :deadlocked
      rescue ActiveRecord::LockWaitTimeout
        :lock_timeout
      end

      def locked_by?(process_uuid)
        locked_by.eql?(process_uuid)
      end

      def recently_locked?
        locked_by && locked_at > 10.minutes.ago
      end

      private
      def self.lock_for_split_key(message_format, split_key)
        lock.find_by(format: message_format, split_key: split_key)
      end

      def self.get_lock_record(message_format, split_key)
        l = lock_for_split_key(message_format, split_key)
        if l.nil?
          begin
            l = create!(format: message_format, split_key: split_key)
          rescue ActiveRecord::RecordNotUnique
            l = lock_for_split_key(message_format, split_key)
          end
        end
        l
      end
    end
  end
end
