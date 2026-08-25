# frozen_string_literal: true

require_relative "frames"

module RailsEventStore
  module Inspector
    class Collector
      HANDLER_FRAMES = :res_inspector_handlers
      BROKER_FRAMES = :res_inspector_brokers
      CURRENT_REQUEST = :res_inspector_request_id

      INFRA_PREFIXES = %w[RubyEventStore:: RailsEventStore::].freeze

      def initialize(buffer, notifications)
        @buffer = buffer
        @notifications = notifications
        @handlers = Frames.new(HANDLER_FRAMES)
        @brokers = Frames.new(BROKER_FRAMES)
      end

      def subscribe
        @notifications.subscribe("call.broker.ruby_event_store", broker_subscriber)
        @notifications.subscribe("call.dispatcher.ruby_event_store", dispatcher_subscriber)


        @notifications.subscribe("enqueue.active_job") do |_name, _start, _finish, _id, payload|
          next unless Inspector.active?
          guarded do
            @buffer.push(
              kind: :enqueued,
              scope: Inspector.scope,
              started_at: now,
              request_id: Thread.current[CURRENT_REQUEST],
              job: payload[:job].class.name,
            )
          end
        end
      end

      private

      def broker_subscriber
        Subscriber.new(
          start: guard(->(_payload) { @brokers.push(started_at: now, producer: @handlers.top&.fetch(:label)) }),
          finish:
            guard(
              lambda do |payload|
              frame = @brokers.pop or return
              event = payload[:event]
              Thread.current[CURRENT_REQUEST] = metadata(event)[:request_id]
              @buffer.push(
                kind: :event,
                scope: Inspector.scope,
                started_at: frame[:started_at],
                duration: now - frame[:started_at],
                producer: frame[:producer],
                request_id: metadata(event)[:request_id],
                event_id: event.event_id,
                causation_id: metadata(event)[:causation_id],
                correlation_id: metadata(event)[:correlation_id],
                event_type: event.event_type,
              )
            end,
            ),
        )
      end

      def dispatcher_subscriber
        Subscriber.new(
          start:
            guard(
              lambda do |payload|
              subscriber = payload[:subscriber]
              label = label_for(subscriber)
              @handlers.push(label: label, started_at: now, infra: infra?(label), async: async?(subscriber))
            end,
            ),
          finish:
            guard(
              lambda do |payload|
              frame = @handlers.pop or return
              event = payload[:event]
              @buffer.push(
                kind: :handler,
                scope: Inspector.scope,
                started_at: frame[:started_at],
                duration: now - frame[:started_at],
                request_id: metadata(event)[:request_id],
                event_id: event.event_id,
                subscriber: frame[:label],
                infra: frame[:infra],
                async: frame[:async],
              )
            end,
            ),
        )
      end

      def now
        Process.clock_gettime(Process::CLOCK_MONOTONIC)
      end

      def guard(callable)
        lambda do |payload|
          callable.call(payload)
        rescue StandardError => e
          report(e)
          nil
        end
      end

      def guarded
        yield
      rescue StandardError => e
        report(e)
        nil
      end

      def report(error)
        if defined?(::Rails) && ::Rails.respond_to?(:error) && ::Rails.error
          ::Rails.error.report(error, handled: true, severity: :warning, context: { gem: "rails_event_store-inspector" })
        else
          warn_once(error)
        end
      rescue StandardError
        nil
      end

      def warn_once(error)
        return if defined?(@warned)
        @warned = true
        Kernel.warn("[res-inspector] collecting failed and was skipped: #{error.class}: #{error.message}")
      end

      def metadata(event)
        event.metadata
      rescue StandardError
        {}
      end

      def infra?(label)
        INFRA_PREFIXES.any? { |prefix| label.to_s.start_with?(prefix) }
      end

      def async?(subscriber)
        return false unless subscriber.is_a?(Class)
        return false unless defined?(::ActiveJob::Base)

        !!(subscriber < ::ActiveJob::Base)
      end

      def label_for(subscriber)
        case subscriber
        when Class, Module
          subscriber.name
        when Proc
          file, line = subscriber.source_location
          "#<Proc @ #{relative(file)}:#{line}>"
        else
          subscriber.class.name
        end
      end

      def relative(path)
        return path if path.nil?
        root = defined?(::Rails) && ::Rails.respond_to?(:root) && ::Rails.root
        return path unless root
        path.start_with?(root.to_s) ? path.delete_prefix("#{root}/") : path
      end

      class Subscriber
        def initialize(start:, finish:)
          @start = start
          @finish = finish
        end

        def start(_name, _id, payload)
          return unless Inspector.active?
          @start.call(payload)
        end

        def finish(_name, _id, payload)
          return unless Inspector.active?
          @finish.call(payload)
        end
      end
    end
  end
end
