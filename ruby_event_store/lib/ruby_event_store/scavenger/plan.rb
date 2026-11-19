# frozen_string_literal: true

module RubyEventStore
  module Scavenger
    # What one scavenger run would do to one stream. A scavenge strategy computes it without
    # changing anything.
    #
    # stream   - the stream (Stream)
    # boundary - the entry up to which visible entries are to be hidden, in the strategy's own
    #            terms (a row id in SQL, never a position); nil when nothing is to be hidden
    # reasons  - the rules that set the boundary, any of REASONS
    # to_mark  - visible entries up to the boundary, to be hidden by MARK
    # to_sweep - hidden entries marked before the sweep cutoff, to be removed by SWEEP; the
    #            position anchor and the tombstone sentinel are never counted
    # to_purge - with policy :purge, events of entries to sweep that no other stream links to,
    #            to be removed after their links; 0 with :links_only
    class Plan < Data.define(:stream, :boundary, :reasons, :to_mark, :to_sweep, :to_purge)
      # truncate_before - truncate_stream
      # soft_delete     - soft_delete_stream
      # max_count       - retention: the stream keeps that many visible entries, the newest
      # max_age         - retention: an entry stays that many seconds after it was linked
      REASONS = %i[truncate_before soft_delete max_count max_age].freeze

      def empty?
        to_mark.zero? && to_sweep.zero?
      end
    end
  end
end
