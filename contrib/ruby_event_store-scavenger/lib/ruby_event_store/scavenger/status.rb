# frozen_string_literal: true

module RubyEventStore
  module Scavenger
    # Where the scavenger is, as recorded by the last run that changed anything.
    #
    # status     - :idle, :marking, :sweeping or :purging (SWEEP with policy :purge)
    # stream     - name of the stream being marked, swept or purged; nil when idle
    # cursor     - name of the last stream a run finished; the next run starts after it,
    #              nil when the last run went through every stream
    # updated_at - time of the record; nil when no run has been recorded yet
    class Status < Data.define(:status, :stream, :cursor, :updated_at)
      def self.initial
        new(status: :idle, stream: nil, cursor: nil, updated_at: nil)
      end

      def to_s
        [
          "status: #{status}",
          "stream: #{stream || "-"}",
          "cursor: #{cursor || "-"}",
          "updated_at: #{updated_at&.iso8601(TIMESTAMP_PRECISION) || "-"}",
        ].join("\n")
      end
    end
  end
end
