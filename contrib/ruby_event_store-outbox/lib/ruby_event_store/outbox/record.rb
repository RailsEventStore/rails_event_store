# frozen_string_literal: true

require 'active_record'

module RubyEventStore
  module Outbox
    class Record < ::ActiveRecord::Base
      self.primary_key = :id
      self.table_name = 'event_store_outbox'

      def self.remaining_for(fetch_specification)
        where(format: fetch_specification.message_format, split_key: fetch_specification.split_key, enqueued_at: nil)
      end

      def hash_payload
        JSON.parse(payload).deep_symbolize_keys
      end

      def enqueued?
        !enqueued_at.nil?
      end
    end

    class Lock < ::ActiveRecord::Base
      self.table_name = 'event_store_outbox_locks'

      def self.obtain(fetch_specification, process_uuid, clock:)
        l = nil
        transaction do
          l = get_lock_record(fetch_specification)

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

      def refresh(clock:)
        transaction do
          current_process_uuid = locked_by
          lock!
          if locked_by == current_process_uuid
            update!(locked_at: clock.now)
            return self
          else
            return :stolen
          end
        end
      rescue ActiveRecord::Deadlocked
        :deadlocked
      rescue ActiveRecord::LockWaitTimeout
        :lock_timeout
      end

      def self.release(fetch_specification, process_uuid)
        transaction do
          l = get_lock_record(fetch_specification)
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
      def self.lock_for_split_key(fetch_specification)
        lock.find_by(format: fetch_specification.message_format, split_key: fetch_specification.split_key)
      end

      def self.get_lock_record(fetch_specification)
        l = lock_for_split_key(fetch_specification)
        if l.nil?
          begin
            l = create!(format: fetch_specification.message_format, split_key: fetch_specification.split_key)
          rescue ActiveRecord::RecordNotUnique
            l = lock_for_split_key(fetch_specification)
          end
        end
        l
      end
    end
  end
end
