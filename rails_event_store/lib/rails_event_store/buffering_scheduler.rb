# frozen_string_literal: true

module RailsEventStore
  module BufferingScheduler
    BUFFER_KEY = :rails_event_store_scheduler_buffers

    def flush
      entries = buffers.delete(self) || []
      return if entries.empty?

      ship(entries)
    end

    private

    def buffer
      buffers[self] ||= []
    end

    # Keyed by thread as well as by scheduler identity, because #call and #flush
    # run on the same thread inside commit_records, and two schedulers sharing a
    # dispatcher must not drain each other's entries.
    def buffers
      Thread.current[BUFFER_KEY] ||= {}.compare_by_identity
    end
  end
end
