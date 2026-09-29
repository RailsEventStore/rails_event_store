# frozen_string_literal: true

require "active_job"

module RubyEventStore
  module OutboxRelay
    # Delivers to ActiveJob subscribers, one job per delivery.
    #
    # Unlike RailsEventStore::ActiveJobScheduler it can enqueue a whole batch
    # with one ActiveJob.perform_all_later, which adapters turn into a single
    # round trip (Sidekiq's push_bulk, an insert_all of jobs, ...) instead of
    # one per job. The adapter is expected to mark each job it enqueued
    # (job.successfully_enqueued), as ActiveJob's own adapters do: a job left
    # unmarked is reported as not enqueued and retried.
    #
    # ActiveJob.perform_all_later skips the enqueue callbacks (before_enqueue,
    # around_enqueue, after_enqueue), and enqueues a job even when one of them
    # would have halted it. So only jobs without enqueue callbacks of their own
    # are enqueued in bulk; the others are enqueued one by one, callbacks
    # included. The callbacks ActiveJob adds itself (logging, instrumentation)
    # don't count.
    class ActiveJobDispatcher
      ACTIVE_JOB_DIRECTORY = "#{File.dirname(::ActiveJob.method(:gem_version).source_location.first)}/".freeze
      private_constant :ACTIVE_JOB_DIRECTORY

      # Raised for a job that a bulk enqueue reports as not enqueued.
      class NotEnqueued < StandardError; end

      # @param serializer [#dump] serializes the record into the job's payload;
      #   the subscriber's job is expected to deserialize it the same way
      def initialize(serializer:)
        @serializer = serializer
      end

      # Enqueues one job, callbacks included.
      #
      # @param subscriber [Class] an ActiveJob class
      # @param record [RubyEventStore::Record]
      # @raise [ActiveJob::EnqueueError] when the adapter failed to enqueue the job.
      #   A job that an enqueue callback halted is not an error, as it isn't for
      #   ActiveJob itself
      def call(subscriber, _event, record)
        error = enqueue_one(subscriber.new(payload_for(record)))
        raise error if error
      end

      # Enqueues the deliveries, in bulk where the job allows it.
      #
      # When a bulk enqueue fails as a whole, its jobs are enqueued one by one,
      # so a single job can't take the others down. A job that had already been
      # pushed before the failure may then be pushed twice, in keeping with
      # at-least-once delivery.
      #
      # @param deliveries [Array<AsyncSubscriptions::Delivery>]
      # @return [Array<Exception, nil>] for each delivery, why it wasn't enqueued, or nil
      def call_all(deliveries)
        results = Array.new(deliveries.size)
        bulk = []
        deliveries.each_with_index do |delivery, index|
          job = delivery.subscriber.new(payload_for(delivery.record))
          bulk?(delivery.subscriber) ? bulk << [index, job] : results[index] = enqueue_one(job)
        end
        enqueue_bulk(bulk, results)
        results
      end

      # @param subscriber [Class, Object]
      # @return [Boolean]
      def verify(subscriber)
        Class === subscriber && !!(subscriber < ActiveJob::Base)
      end

      private

      attr_reader :serializer

      def payload_for(record)
        record.serialize(serializer).to_h.transform_keys(&:to_s)
      end

      def bulk?(subscriber)
        subscriber._enqueue_callbacks.all? { |callback| built_in?(callback) }
      end

      def built_in?(callback)
        callback.filter.respond_to?(:source_location) &&
          callback.filter.source_location.first.start_with?(ACTIVE_JOB_DIRECTORY)
      end

      def enqueue_bulk(bulk, results)
        return if bulk.empty?
        ActiveJob.perform_all_later(bulk.map(&:last))
        bulk.each { |index, job| results[index] = not_enqueued(job) unless job.successfully_enqueued? }
      rescue StandardError
        bulk.each { |index, job| results[index] = enqueue_one(job) }
      end

      def not_enqueued(job)
        job.enqueue_error || NotEnqueued.new("#{job.class} was not enqueued")
      end

      def enqueue_one(job)
        job.enqueue
        job.enqueue_error
      rescue StandardError => e
        e
      end
    end
  end
end
