# frozen_string_literal: true

require "spec_helper"
require "ruby_event_store/spec/scheduler_lint"

module RailsEventStore
  ::RSpec.describe ActiveJobBulkScheduler do
    around { |example| ActiveJob::Base.with(logger: nil, queue_adapter: :test) { example.run } }

    it_behaves_like "scheduler", ActiveJobBulkScheduler.new(serializer: RubyEventStore::Serializers::YAML)
    it_behaves_like "scheduler", ActiveJobBulkScheduler.new(serializer: RubyEventStore::NULL)
    it_behaves_like "scheduler", ActiveJobBulkScheduler.new(serializer: JSON)

    let(:scheduler) { ActiveJobBulkScheduler.new(serializer: RubyEventStore::Serializers::YAML) }

    let(:event) do
      TimeEnrichment.with(
        RubyEventStore::Event.new(event_id: "83c3187f-84f6-4da7-8206-73af5aca7cc8"),
        timestamp: Time.utc(2026, 8, 25),
      )
    end
    let(:record) { RubyEventStore::Mappers::Default.new.event_to_record(event) }

    def enqueued_jobs
      ActiveJob::Base.queue_adapter.enqueued_jobs
    end

    specify "enqueues the same payload ActiveJobScheduler does" do
      timestamp = event.metadata[:timestamp].iso8601(RubyEventStore::TIMESTAMP_PRECISION)

      scheduler.call(MyBulkAsyncHandler, record)
      scheduler.flush

      expect(enqueued_jobs).to match(
        [
          hash_including(
            job: MyBulkAsyncHandler,
            queue: "default",
            args: [
              {
                "event_id" => event.event_id,
                "event_type" => "RubyEventStore::Event",
                "data" => "--- {}\n",
                "metadata" => "--- {}\n",
                "timestamp" => timestamp,
                "valid_at" => timestamp,
                "_aj_symbol_keys" => [],
              },
            ],
          ),
        ],
      )
    end

    describe "#verify" do
      specify "accepts an ActiveJob class" do
        expect(scheduler.verify(MyBulkAsyncHandler)).to be(true)
      end

      specify "accepts an ActiveJob::ConfiguredJob" do
        expect(scheduler.verify(MyBulkAsyncHandler.set(queue: "specific"))).to be(true)
      end

      specify "rejects a class that is not an ActiveJob" do
        expect(scheduler.verify(Class.new)).to be(false)
      end

      specify "rejects ActiveJob::Base itself" do
        expect(scheduler.verify(ActiveJob::Base)).to be(false)
      end

      specify "rejects an arbitrary object" do
        expect(scheduler.verify(Object.new)).to be(false)
      end
    end

    class MyBulkAsyncHandler < ActiveJob::Base
      def perform(event)
      end
    end
  end
end
