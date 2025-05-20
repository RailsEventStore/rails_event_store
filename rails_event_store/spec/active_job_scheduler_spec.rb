# frozen_string_literal: true

require "spec_helper"
require "ruby_event_store/spec/scheduler_lint"

module RailsEventStore
  ::RSpec.describe ActiveJobScheduler do
    around { |example| ActiveJob::Base.with(logger: nil, queue_adapter: :test) { example.run } }

    before { MyAsyncHandler.reset }

    it_behaves_like "scheduler", ActiveJobScheduler.new(serializer: RubyEventStore::Serializers::YAML)
    it_behaves_like "scheduler", ActiveJobScheduler.new(serializer: RubyEventStore::NULL)
    it_behaves_like "scheduler", ActiveJobScheduler.new(serializer: JSON)

    let(:event) do
      TimeEnrichment.with(Event.new(event_id: "83c3187f-84f6-4da7-8206-73af5aca7cc8"), timestamp: Time.utc(2019, 9, 30))
    end
    let(:record) { RubyEventStore::Mappers::Default.new.event_to_record(event) }

    describe "#verify" do
      let(:scheduler) { ActiveJobScheduler.new(serializer: RubyEventStore::NULL) }
      let(:proper_handler) { Class.new(ActiveJob::Base) }

      specify { expect(scheduler.verify(proper_handler)).to be(true) }

      specify "ActiveJob::ConfiguredJob is also acceptable" do
        expect(scheduler.verify(proper_handler.set({}))).to be(true)
      end

      specify do
        some_class = Class.new
        expect(scheduler.verify(some_class)).to be(false)
      end

      specify { expect(scheduler.verify(ActiveJob::Base)).to be(false) }

      specify { expect(scheduler.verify(Object.new)).to be(false) }
    end

    describe "#call" do
      let(:scheduler) { ActiveJobScheduler.new(serializer: RubyEventStore::Serializers::YAML) }

      specify do
        scheduler.call(MyAsyncHandler, record)

        enqueued_jobs = ActiveJob::Base.queue_adapter.enqueued_jobs
        expect(enqueued_jobs.size).to eq(1)
        expect(enqueued_jobs[0]).to include(
          {
            job: MyAsyncHandler,
            args: [
              {
                "event_id" => "83c3187f-84f6-4da7-8206-73af5aca7cc8",
                "event_type" => "RubyEventStore::Event",
                "data" => "--- {}\n",
                "metadata" => "--- {}\n",
                "timestamp" => "2019-09-30T00:00:00.000000Z",
                "valid_at" => "2019-09-30T00:00:00.000000Z",
                "_aj_symbol_keys" => [],
              },
            ],
            queue: "default",
          },
        )
      end

      specify "pass ActiveJob::ConfiguredJob" do
        scheduler.call(MyAsyncHandler.set(queue: "non-default"), record)

        enqueued_jobs = ActiveJob::Base.queue_adapter.enqueued_jobs
        expect(enqueued_jobs.size).to eq(1)
        expect(enqueued_jobs[0]).to include(
          {
            job: MyAsyncHandler,
            args: [
              {
                "event_id" => "83c3187f-84f6-4da7-8206-73af5aca7cc8",
                "event_type" => "RubyEventStore::Event",
                "data" => "--- {}\n",
                "metadata" => "--- {}\n",
                "timestamp" => "2019-09-30T00:00:00.000000Z",
                "valid_at" => "2019-09-30T00:00:00.000000Z",
                "_aj_symbol_keys" => [],
              },
            ],
            queue: "non-default",
          },
        )
      end
    end

    class MyAsyncHandler < ActiveJob::Base
      @@received = nil
      def self.reset
        @@received = nil
      end
      def self.received
        @@received
      end
      def perform(event)
        @@received = event
      end
    end
  end
end
