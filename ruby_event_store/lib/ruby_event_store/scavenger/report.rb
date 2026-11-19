# frozen_string_literal: true

module RubyEventStore
  module Scavenger
    # Outcome of a scavenger run. In a dry run marked and swept are what the run would do.
    #
    # policy  - Policy
    # dry_run - true when nothing was changed
    # outcome - :finished    every selected stream was processed
    #           :interrupted max_duration ran out; the next run resumes where this one stopped
    #           :locked      another run holds the lock; this one did nothing
    # streams - a StreamResult for each stream where something was (or would be) marked or swept
    class Report < Data.define(:policy, :dry_run, :outcome, :streams)
      # stream  - Stream
      # reasons - as in Plan
      # marked  - entries hidden by MARK
      # swept   - entries removed by SWEEP
      # purged  - events removed after their links (policy :purge); 0 with :links_only
      StreamResult = Data.define(:stream, :reasons, :marked, :swept, :purged)

      def marked
        streams.sum(&:marked)
      end

      def swept
        streams.sum(&:swept)
      end

      def purged
        streams.sum(&:purged)
      end
    end
  end
end
