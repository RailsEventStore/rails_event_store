# frozen_string_literal: true

require "securerandom"

module RubyEventStore
  module Scavenger
    NotAllowed = Class.new(Error)
    GracePeriodTooShort = Class.new(Error)

    # Physical removal of hidden stream entries, as a process apart from the application.
    #
    #   RubyEventStore::Scavenger::Runner.new(
    #     repository: RubyEventStore::ActiveRecord::EventRepository.new(serializer: JSON),
    #     strategy: RubyEventStore::ActiveRecord::ScavengeStrategy.new,
    #   ).call(dry_run: false)
    #
    # Goes through the streams with metadata, by name, starting after the cursor of the previous
    # run. For each one MARK hides what retention (max_count, max_age), truncate_stream and
    # soft_delete_stream say should be hidden, then SWEEP removes the links of entries hidden
    # longer ago than grace_period (policy :links_only: events stay in the global stream). A
    # stream that lost links gets StreamScavenged in its meta stream. A run stops cleanly once
    # max_duration has passed; the next one resumes with the stream it stopped at.
    #
    # A dry run is the default: it changes nothing, takes no lock, writes no status, starts from
    # the first stream, and reports what a run would mark and sweep now.
    #
    # Refuses to run unless ENV["RES_SCAVENGER"] is set or allow_in_process: true is passed, so
    # that an application which loads the gem by accident does not remove data.
    #
    # repository - the native repository (not decorated), for StreamScavenged
    # base       - the ActiveRecord class whose connection holds the lock and the status
    # streams    - :all, an Array of stream names, or a callable taking a name
    # throttle   - seconds to sleep between batches
    class Runner
      DEFAULT_GRACE_PERIOD = 7 * 24 * 3600
      DEFAULT_BATCH_SIZE = 1_000

      # A runner on the tables of RubyEventStore::ActiveRecord::EventRepository.
      def self.active_record(serializer:, model_factory: ActiveRecord::WithDefaultModels.new, **options)
        new(
          repository: ActiveRecord::EventRepository.new(serializer: serializer, model_factory: model_factory),
          strategy: ActiveRecord::ScavengeStrategy.new(model_factory: model_factory),
          **options,
        )
      end

      def initialize(
        repository:,
        strategy:,
        policy: :links_only,
        batch_size: DEFAULT_BATCH_SIZE,
        grace_period: DEFAULT_GRACE_PERIOD,
        force: false,
        max_duration: 300,
        throttle: 0,
        streams: :all,
        base: ::ActiveRecord::Base,
        state: State.new(base: base),
        lock: Lock.new(base: base, state: state),
        instrumentation: ActiveSupport::Notifications,
        allow_in_process: false,
        env: ENV,
        clock: -> { Time.now },
        sleeper: ->(seconds) { Kernel.sleep(seconds) }
      )
        if grace_period < DEFAULT_GRACE_PERIOD && !force
          raise GracePeriodTooShort, "A grace period shorter than #{DEFAULT_GRACE_PERIOD} seconds needs force"
        end
        @repository = repository
        @strategy = strategy
        @policy = Policy.of(policy)
        @batch_size = batch_size
        @grace_period = grace_period
        @max_duration = max_duration
        @throttle = throttle
        @streams = streams
        @state = state
        @lock = lock
        @instrumentation = instrumentation
        @allow_in_process = allow_in_process
        @env = env
        @clock = clock
        @sleeper = sleeper
      end

      # @return [Report]
      def call(dry_run: true)
        unless allow_in_process || env.key?("RES_SCAVENGER")
          raise NotAllowed,
                "Set RES_SCAVENGER in the environment of the scavenger process or pass allow_in_process: true"
        end
        payload = { policy: policy, dry_run: dry_run }
        instrumentation.instrument("scavenge.ruby_event_store", payload) do
          payload[:report] = dry_run ? run(true) : execute
        end
      end

      private

      attr_reader :repository,
                  :strategy,
                  :policy,
                  :batch_size,
                  :grace_period,
                  :max_duration,
                  :throttle,
                  :streams,
                  :state,
                  :lock,
                  :instrumentation,
                  :allow_in_process,
                  :env,
                  :clock,
                  :sleeper

      def execute
        report = nil
        return report if lock.synchronize { report = run(false) }
        Report.new(policy: policy, dry_run: false, outcome: :locked, streams: [])
      end

      def run(dry_run)
        @dry_run = dry_run
        @deadline = clock.call + max_duration
        @interrupted = false
        @results = []
        cursor = state.status.cursor unless dry_run
        until @interrupted || (page = strategy.streams(after: cursor, limit: batch_size)).empty?
          page.each do |stream|
            break if timed_out?
            scavenge(stream, cursor) if selected?(stream)
            break if @interrupted
            cursor = stream.name
          end
          save(:idle, nil, cursor)
        end
        cursor = nil unless @interrupted
        save(:idle, nil, cursor)
        Report.new(
          policy: policy,
          dry_run: dry_run,
          outcome: @interrupted ? :interrupted : :finished,
          streams: @results,
        )
      end

      def selected?(stream)
        case streams
        when :all
          true
        when Array
          streams.include?(stream.name)
        else
          streams.call(stream.name)
        end
      end

      def scavenge(stream, cursor)
        now = clock.call
        plan = strategy.plan(stream, now: now, sweep_before: now - grace_period)
        return if plan.empty?
        counts = { mark: 0, sweep: 0 }
        instrumentation.instrument(
          "scavenge_stream.ruby_event_store",
          stream: stream,
          reasons: plan.reasons,
          dry_run: @dry_run,
        ) do |payload|
          if @dry_run
            counts = { mark: plan.to_mark, sweep: plan.to_sweep }
          else
            mark_and_sweep(plan, now, cursor, counts)
          end
          payload.merge!(marked: counts.fetch(:mark), swept: counts.fetch(:sweep))
        end
        record(plan, counts)
      end

      def mark_and_sweep(plan, now, cursor, counts)
        stream = plan.stream
        save(:marking, stream.name, cursor)
        batches(:mark, stream, counts) { strategy.mark(plan, batch_size, now: now) }
        unless @interrupted
          save(:sweeping, stream.name, cursor)
          sweep_before = clock.call - grace_period
          batches(:sweep, stream, counts) { strategy.sweep(stream, batch_size, before: sweep_before) }
        end
        record_scavenged(stream, counts.fetch(:sweep))
      end

      def batches(phase, stream, counts)
        loop do
          size =
            instrumentation.instrument("scavenge_batch.ruby_event_store", stream: stream, phase: phase) do |payload|
              payload[:size] = yield
            end
          counts[phase] += size
          break if size < batch_size || timed_out?
          sleeper.call(throttle) unless throttle.zero?
        end
      end

      def timed_out?
        @interrupted = clock.call >= @deadline
      end

      def record(plan, counts)
        @results << Report::StreamResult.new(
          stream: plan.stream,
          reasons: plan.reasons,
          marked: counts.fetch(:mark),
          swept: counts.fetch(:sweep),
        )
      end

      def record_scavenged(stream, swept)
        return if swept.zero?
        timestamp = clock.call.round(TIMESTAMP_PRECISION)
        record =
          Record.new(
            event_id: SecureRandom.uuid,
            event_type: StreamMetadataEvents::StreamScavenged.name,
            data: {
              "stream" => stream.name,
              "policy" => policy.to_s,
              "removed_links" => swept,
              "removed_events" => 0,
            },
            metadata: {
            },
            timestamp: timestamp,
            valid_at: timestamp,
          )
        repository.append_stream_metadata(record, stream, ExpectedVersion.any)
      end

      def save(status, stream, cursor)
        state.save(status: status, stream: stream, cursor: cursor) unless @dry_run
      end
    end
  end
end
