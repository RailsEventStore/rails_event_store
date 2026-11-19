# frozen_string_literal: true

module RubyEventStore
  module Scavenger
    # The scavenger's record in event_store_scavenger_state: its Status (the cursor is kept in
    # last_stream) and, where the database has no advisory locks, its lock. One row, written only
    # by the run that holds the lock.
    class State
      TABLE = "event_store_scavenger_state"
      NAME = "res_scavenger"

      def initialize(base: ::ActiveRecord::Base, clock: -> { Time.now })
        @base = base
        @clock = clock
      end

      # @return [Status]
      def status
        status, stream, cursor, updated_at = row.pick(:status, :stream, :last_stream, :updated_at)
        return Status.initial if status.nil?
        Status.new(status: status.to_sym, stream: stream, cursor: cursor, updated_at: updated_at)
      end

      def save(status:, stream:, cursor:)
        create
        row.update_all(status: status, stream: stream, last_stream: cursor, updated_at: clock.call)
      end

      # Takes the lock unless a live owner holds it: one whose lock is not older than stale_before.
      # @return [Boolean] whether owner holds the lock now
      def claim(owner, stale_before:)
        create
        table = model.arel_table
        row
          .where(table[:locked_by].eq(nil).or(table[:locked_at].lt(stale_before)))
          .update_all(locked_by: owner, locked_at: clock.call)
          .positive?
      end

      def release(owner)
        row.where(locked_by: owner).update_all(locked_by: nil, locked_at: nil)
      end

      private

      attr_reader :clock

      # Inserts the record unless it is there.
      def create
        model.insert_all([{ name: NAME, status: "idle", updated_at: clock.call }])
      end

      def row
        model.where(name: NAME)
      end

      def model
        @model ||= Class.new(@base) { self.table_name = TABLE }
      end
    end
  end
end
