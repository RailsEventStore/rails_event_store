# frozen_string_literal: true

require "spec_helper"

module RubyEventStore
  module OutboxRelay
    ::RSpec.describe ActiveJobDispatcher do
      let(:serializer) { RubyEventStore::Serializers::YAML }
      let(:dispatcher) { ActiveJobDispatcher.new(serializer: serializer) }
      let(:log) { [] }

      def job_class(name, callbacks: false, adapter: :test, &body)
        log = self.log
        klass =
          Class.new(ActiveJob::Base) do
            self.queue_adapter = adapter
            define_method(:perform) { |_payload| nil }
            if callbacks
              before_enqueue { log << [name, :before_enqueue] }
              around_enqueue do |_job, block|
                log << [name, :around_enqueue]
                block.call
              end
            end
            class_exec(&body) if body
          end
        stub_const(name, klass)
      end

      def record_for(event = TestEvent.new(data: { "a" => 1 }))
        now = Time.utc(2026, 9, 29, 12)
        RubyEventStore::Record.new(
          event_id: event.event_id,
          data: event.data,
          metadata: event.metadata.to_h,
          event_type: event.event_type,
          timestamp: now,
          valid_at: now,
        )
      end

      def delivery(subscriber, record = record_for)
        AsyncSubscriptions::Delivery.new(subscriber: subscriber, event: double(:event), record: record)
      end

      def enqueued(klass)
        klass.queue_adapter.enqueued_jobs.map { |job| job.fetch(:args).first }
      end

      describe "#call" do
        specify "enqueues one job with the record serialized as its payload" do
          klass = job_class("SingleJob")
          record = record_for

          dispatcher.call(klass, double(:event), record)

          expect(enqueued(klass)).to eq([record.serialize(serializer).to_h.transform_keys(&:to_s).merge("_aj_symbol_keys" => [])])
        end

        specify "runs the enqueue callbacks" do
          klass = job_class("SingleJob", callbacks: true)

          dispatcher.call(klass, double(:event), record_for)

          expect(log).to eq([["SingleJob", :before_enqueue], ["SingleJob", :around_enqueue]])
        end
      end

      describe "#call when the adapter fails to enqueue" do
        specify "raises the ActiveJob::EnqueueError, which ActiveJob itself swallows" do
          klass = job_class("DownJob", adapter: RaisingAdapter.new(ActiveJob::EnqueueError.new("queue down")))

          expect { dispatcher.call(klass, double(:event), record_for) }.to raise_error(ActiveJob::EnqueueError, "queue down")
        end

        specify "doesn't treat a job halted by an enqueue callback as an error" do
          klass = job_class("HaltedJob") { before_enqueue { throw :abort } }

          expect { dispatcher.call(klass, double(:event), record_for) }.not_to raise_error
          expect(klass.queue_adapter.enqueued_jobs).to be_empty
        end

        specify "raises any other error of the adapter as well" do
          klass = job_class("DownJob", adapter: RaisingAdapter.new(RuntimeError.new("boom")))

          expect { dispatcher.call(klass, double(:event), record_for) }.to raise_error(RuntimeError, "boom")
        end
      end

      describe "#call_all" do
        specify "reports the ActiveJob::EnqueueError of a job with enqueue callbacks, which #enqueue swallows" do
          klass = job_class("DownJob", callbacks: true, adapter: RaisingAdapter.new(ActiveJob::EnqueueError.new("queue down")))

          results = dispatcher.call_all([delivery(klass)])

          expect(results.sole).to be_an_instance_of(ActiveJob::EnqueueError)
          expect(results.sole.message).to eq("queue down")
        end

        specify "reports why a job the bulk enqueue did not enqueue failed, when ActiveJob says" do
          klass = job_class("BulkJob")
          error = ActiveJob::EnqueueError.new("queue down")
          allow(ActiveJob).to receive(:perform_all_later) do |jobs|
            jobs.each do |job|
              job.successfully_enqueued = false
              job.enqueue_error = error
            end
          end

          results = dispatcher.call_all([delivery(klass)])

          expect(results.sole).to equal(error)
        end

        specify "enqueues every delivery, with the payload of its record, and reports no failures" do
          klass = job_class("BulkJob")
          first, second = record_for, record_for

          results = dispatcher.call_all([delivery(klass, first), delivery(klass, second)])

          expect(results).to eq([nil, nil])
          expect(enqueued(klass).map { |payload| payload.fetch("event_id") }).to eq([first.event_id, second.event_id])
        end

        specify "enqueues jobs without enqueue callbacks with a single ActiveJob.perform_all_later" do
          klass = job_class("BulkJob")
          allow(ActiveJob).to receive(:perform_all_later).and_call_original

          dispatcher.call_all([delivery(klass), delivery(klass), delivery(klass)])

          expect(ActiveJob).to have_received(:perform_all_later).once.with(
            [an_instance_of(klass), an_instance_of(klass), an_instance_of(klass)],
          )
        end

        specify "enqueues jobs with enqueue callbacks one by one, running the callbacks" do
          klass = job_class("HookedJob", callbacks: true)
          allow(ActiveJob).to receive(:perform_all_later).and_call_original

          dispatcher.call_all([delivery(klass), delivery(klass)])

          expect(ActiveJob).not_to have_received(:perform_all_later)
          expect(log).to eq([[ "HookedJob", :before_enqueue], ["HookedJob", :around_enqueue]] * 2)
          expect(klass.queue_adapter.enqueued_jobs.size).to eq(2)
        end

        specify "enqueues a job whose enqueue callback is a named method one by one, too" do
          klass = job_class("NamedHookJob") do
            before_enqueue :note
            define_method(:note) { nil }
          end
          allow(ActiveJob).to receive(:perform_all_later).and_call_original

          dispatcher.call_all([delivery(klass)])

          expect(ActiveJob).not_to have_received(:perform_all_later)
          expect(klass.queue_adapter.enqueued_jobs.size).to eq(1)
        end

        specify "enqueues a job that inherits an enqueue callback one by one, too" do
          parent = job_class("ParentJob", callbacks: true)
          child = stub_const("ChildJob", Class.new(parent))
          allow(ActiveJob).to receive(:perform_all_later).and_call_original

          dispatcher.call_all([delivery(child)])

          expect(ActiveJob).not_to have_received(:perform_all_later)
          expect(log.map(&:last)).to eq(%i[before_enqueue around_enqueue])
        end

        specify "honors a callback that halts the enqueue, like #call" do
          klass = job_class("HaltingJob") { before_enqueue { throw :abort } }

          results = dispatcher.call_all([delivery(klass)])

          expect(results).to eq([nil])
          expect(klass.queue_adapter.enqueued_jobs).to be_empty
        end

        specify "keeps the results in the order of the deliveries, whichever way each one was enqueued" do
          plain = job_class("PlainJob")
          hooked = job_class("HookedJob", callbacks: true)
          failing = job_class("FailingHookedJob", callbacks: true, adapter: FailingAdapter.new(fail_when: ->(_job) { true }))
          results = dispatcher.call_all([delivery(plain), delivery(failing), delivery(hooked), delivery(plain)])

          expect(results.map { |result| result&.message }).to eq([nil, "enqueue failed", nil, nil])
        end

        specify "gives every delivery the payload of its own record" do
          klass = job_class("BulkJob")

          dispatcher.call_all([delivery(klass), delivery(klass)])

          expect(enqueued(klass).map { |payload| payload.fetch("event_id") }.uniq.size).to eq(2)
        end

        specify "falls back to enqueueing one by one when the bulk enqueue fails as a whole, isolating each job's failure" do
          adapter = FailingAdapter.new(bulk_fails: true)
          klass = job_class("BulkJob", adapter: adapter)

          results = dispatcher.call_all([delivery(klass), delivery(klass)])

          expect(results).to eq([nil, nil])
          expect(adapter.enqueued.size).to eq(2)
        end

        specify "reports the error of the job that can't be enqueued, not of the others" do
          adapter = FailingAdapter.new(bulk_fails: true, fail_when: ->(job) { job.arguments.first.fetch("event_id") == "bad" })
          klass = job_class("BulkJob", adapter: adapter)
          bad = record_for
          bad = RubyEventStore::Record.new(event_id: "bad", data: bad.data, metadata: bad.metadata, event_type: bad.event_type, timestamp: bad.timestamp, valid_at: bad.valid_at)

          results = dispatcher.call_all([delivery(klass), delivery(klass, bad), delivery(klass)])

          expect(results.map { |result| result&.message }).to eq([nil, "enqueue failed", nil])
        end

        specify "reports a job the bulk enqueue says it did not enqueue" do
          klass = job_class("BulkJob")
          allow(ActiveJob).to receive(:perform_all_later) { |jobs| jobs.each { |job| job.successfully_enqueued = false } }

          results = dispatcher.call_all([delivery(klass)])

          expect(results.sole).to be_an_instance_of(ActiveJobDispatcher::NotEnqueued)
          expect(results.sole.message).to eq("BulkJob was not enqueued")
        end

        specify "reports a delivery whose job can't be built, and carries on with the others, enqueueing nothing twice" do
          bulk = job_class("BulkJob")
          hooked = job_class("HookedJob", callbacks: true)
          picky = Class.new do
            def self.dump(value)
              raise ArgumentError, "cannot serialize" if value == { "bad" => true }
              ::YAML.dump(value)
            end
          end
          dispatcher = ActiveJobDispatcher.new(serializer: picky)
          bad = RubyEventStore::Record.new(event_id: SecureRandom.uuid, data: { "bad" => true }, metadata: {}, event_type: "TestEvent", timestamp: Time.utc(2026, 9, 29), valid_at: Time.utc(2026, 9, 29))

          results = dispatcher.call_all([delivery(bulk), delivery(hooked, bad), delivery(bulk, bad), delivery(hooked), delivery(bulk)])

          expect(results.map { |result| result&.message }).to eq([nil, "cannot serialize", "cannot serialize", nil, nil])
          expect(bulk.queue_adapter.enqueued_jobs.size).to eq(2)
          expect(hooked.queue_adapter.enqueued_jobs.size).to eq(1)
        end

        specify "does nothing for no deliveries" do
          allow(ActiveJob).to receive(:perform_all_later)

          expect(dispatcher.call_all([])).to eq([])
          expect(ActiveJob).not_to have_received(:perform_all_later)
        end
      end

      describe "#verify" do
        specify "accepts ActiveJob classes only" do
          expect(dispatcher.verify(job_class("SomeJob"))).to eq(true)
          expect(dispatcher.verify(Class.new)).to eq(false)
          expect(dispatcher.verify(->(_event) {})).to eq(false)
          expect(dispatcher.verify(SomeJob.new({}))).to eq(false)
        end
      end

      class RaisingAdapter
        def initialize(error)
          @error = error
        end

        def enqueue(_job) = raise(@error)
        def enqueue_at(_job, _timestamp) = raise(@error)
        def enqueue_all(_jobs) = raise(@error)
      end

      class FailingAdapter
        attr_reader :enqueued

        def initialize(bulk_fails: false, fail_when: ->(_job) { false })
          @bulk_fails = bulk_fails
          @fail_when = fail_when
          @enqueued = []
        end

        def enqueue(job)
          raise "enqueue failed" if @fail_when.call(job)
          @enqueued << job
        end

        def enqueue_at(job, _timestamp) = enqueue(job)

        def enqueue_all(jobs)
          raise "enqueue failed" if @bulk_fails
          jobs.each { |job| enqueue(job) }
        end
      end
    end
  end
end
