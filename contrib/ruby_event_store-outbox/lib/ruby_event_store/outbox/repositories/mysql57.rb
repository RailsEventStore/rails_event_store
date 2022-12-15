# frozen_string_literal: true

require "active_record"
require "active_support/core_ext/numeric/time.rb"

module RubyEventStore
  module Outbox
    module Repositories
      class Mysql57
        RECENTLY_LOCKED_DURATION = 10.minutes

        class Record < ::ActiveRecord::Base
          self.primary_key = :id
          self.table_name = "event_store_outbox"

          def self.remaining_for(fetch_specification)
            where(format: fetch_specification.message_format, split_key: fetch_specification.split_key, enqueued_at: nil)
          end

          def self.for_fetch_specification(fetch_specification)
            where(format: fetch_specification.message_format, split_key: fetch_specification.split_key)
          end

          def hash_payload
            JSON.parse(payload).deep_symbolize_keys
          end

          def enqueued?
            !enqueued_at.nil?
          end
        end

        class Lock < ::ActiveRecord::Base
          self.table_name = "event_store_outbox_locks"

          def self.obtain(fetch_specification, process_uuid, clock:)
            transaction do
              l = get_lock_record(fetch_specification)

              if l.recently_locked?(clock: clock)
                :taken
              else
                l.update!(locked_by: process_uuid, locked_at: clock.now)
                l
              end
            end
          rescue ::ActiveRecord::Deadlocked
            :deadlocked
          rescue ::ActiveRecord::LockWaitTimeout
            :lock_timeout
          end

          def self.refresh(lock, clock:)
            transaction do
              current_process_uuid = lock.locked_by
              lock_record = Lock.lock.find(lock.id)
              if lock_record.locked_by == current_process_uuid
                lock_record.update!(locked_at: clock.now)
                lock.assign_attributes(lock_record.attributes)
                :ok
              else
                :stolen
              end
            end
          rescue ::ActiveRecord::Deadlocked
            :deadlocked
          rescue ::ActiveRecord::LockWaitTimeout
            :lock_timeout
          end

          def self.release(fetch_specification, process_uuid)
            transaction do
              l = get_lock_record(fetch_specification)
              if !l.locked_by?(process_uuid)
                :not_taken_by_this_process
              else
                l.update!(locked_by: nil, locked_at: nil)
                :ok
              end
            end
          rescue ::ActiveRecord::Deadlocked
            :deadlocked
          rescue ::ActiveRecord::LockWaitTimeout
            :lock_timeout
          end

          def locked_by?(process_uuid)
            locked_by.eql?(process_uuid)
          end

          def recently_locked?(clock:)
            locked_by && locked_at > RECENTLY_LOCKED_DURATION.ago(clock.now)
          end

          def fetch_specification
            FetchSpecification.new(format, split_key)
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
              rescue ::ActiveRecord::RecordNotUnique
                l = lock_for_split_key(fetch_specification)
              end
            end
            l
          end
        end

        def self.build_for_consumer(database_url)
          ::ActiveRecord::Base.establish_connection(database_url) unless ::ActiveRecord::Base.connected?
          if ::ActiveRecord::Base.connection.adapter_name == "Mysql2"
            ::ActiveRecord::Base.connection.execute("SET SESSION innodb_lock_wait_timeout = 1;")
          end
          new
        end

        def insert_record(format, split_key, payload)
          Record.create!(format: format, split_key: split_key, payload: payload)
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

        def refresh_lock(lock, clock:)
          Lock.refresh(lock, clock: clock)
        end

        def mark_as_enqueued(record, now)
          record.update_column(:enqueued_at, now)
        end

        def delete_enqueued_older_than(fetch_specification, duration, limit)
          scope = Record.for_fetch_specification(fetch_specification).where("enqueued_at < ?", duration.ago)
          scope = scope.limit(limit).order(:id) unless limit == :all
          scope.delete_all
          :ok
        rescue ::ActiveRecord::Deadlocked
          :deadlocked
        rescue ::ActiveRecord::LockWaitTimeout
          :lock_timeout
        end
      end
    end
  end
end