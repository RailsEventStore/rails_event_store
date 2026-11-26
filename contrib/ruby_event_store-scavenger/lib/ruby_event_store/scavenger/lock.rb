# frozen_string_literal: true

require "securerandom"
require "socket"

module RubyEventStore
  module Scavenger
    # Lets one scavenger run at a time. PostgreSQL: an advisory lock; MySQL: GET_LOCK; any other
    # database: the lock columns of State, taken over once older than stale_after seconds, which
    # should exceed the max_duration of a run.
    #
    # An advisory lock belongs to a database connection, so the whole run uses the one connection
    # the lock was taken on.
    class Lock
      Advisory = Data.define(:acquire, :release, :acquired)
      POSTGRESQL =
        Advisory.new(
          acquire: "SELECT pg_try_advisory_lock(hashtext('res_scavenger'))",
          release: "SELECT pg_advisory_unlock(hashtext('res_scavenger'))",
          acquired: true,
        )
      MYSQL =
        Advisory.new(
          acquire: "SELECT GET_LOCK('res_scavenger', 0)",
          release: "SELECT RELEASE_LOCK('res_scavenger')",
          acquired: 1,
        )
      DEFAULT_STALE_AFTER = 3600
      ADVISORY = { "postgresql" => POSTGRESQL, "postgis" => POSTGRESQL, "mysql2" => MYSQL, "trilogy" => MYSQL }.freeze

      def initialize(
        base: ::ActiveRecord::Base,
        state: State.new(base: base),
        stale_after: DEFAULT_STALE_AFTER,
        clock: -> { Time.now },
        owner: "#{Socket.gethostname}:#{Process.pid}:#{SecureRandom.hex(4)}"
      )
        @base = base
        @state = state
        @stale_after = stale_after
        @clock = clock
        @owner = owner
      end

      # Runs the block holding the lock.
      # @return [Boolean] false, without running the block, when another run holds the lock
      def synchronize
        @base.connection_pool.with_connection do |connection|
          advisory = ADVISORY[connection.adapter_name.downcase]
          return false unless acquire(advisory, connection)
          begin
            yield
          ensure
            release(advisory, connection)
          end
        end
        true
      end

      private

      def acquire(advisory, connection)
        return @state.claim(@owner, stale_before: @clock.call - @stale_after) if advisory.nil?
        connection.select_value(advisory.acquire).eql?(advisory.acquired)
      end

      def release(advisory, connection)
        return @state.release(@owner) if advisory.nil?
        connection.select_value(advisory.release)
      end
    end
  end
end
