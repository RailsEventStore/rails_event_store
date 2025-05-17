# frozen_string_literal: true

require "spec_helper"
require "ruby_event_store/spec/scheduler_lint"

module RailsEventStore
  RSpec.describe ActiveJobIdOnlyScheduler do
    around do |example|
      begin
        original_logger = ActiveJob::Base.logger
        ActiveJob::Base.logger = nil

        original_adapter = ActiveJob::Base.queue_adapter
        ActiveJob::Base.queue_adapter = :test

        example.run
      ensure
        ActiveJob::Base.logger = original_logger
        ActiveJob::Base.queue_adapter = original_adapter
      end
    end

    before { MyAsyncHandler.reset }

    it_behaves_like "scheduler", ActiveJobIdOnlyScheduler.new

    let(:event) do
      TimeEnrichment.with(Event.new(event_id: "83c3187f-84f6-4da7-8206-73af5aca7cc8"), timestamp: Time.utc(2019, 9, 30))
    end
    let(:record) { RubyEventStore::Mappers::Default.new.event_to_record(event) }

    describe "#verify" do
      specify do
        scheduler = ActiveJobIdOnlyScheduler.new
        proper_handler = Class.new(ActiveJob::Base)
        expect(scheduler.verify(proper_handler)).to be(true)
      end

      specify do
        scheduler = ActiveJobIdOnlyScheduler.new
        some_class = Class.new
        expect(scheduler.verify(some_class)).to be(false)
      end

      specify do
        scheduler = ActiveJobIdOnlyScheduler.new
        expect(scheduler.verify(ActiveJob::Base)).to be(false)
      end

      specify do
        scheduler = ActiveJobIdOnlyScheduler.new
        expect(scheduler.verify(Object.new)).to be(false)
      end
    end

    describe "#call" do
      specify do
        scheduler = ActiveJobIdOnlyScheduler.new
        scheduler.call(MyAsyncHandler, record)

        enqueued_jobs = ActiveJob::Base.queue_adapter.enqueued_jobs
        expect(enqueued_jobs.size).to eq(1)
        expect(enqueued_jobs[0]).to include(
          {
            job: MyAsyncHandler,
            args: [{ "event_id" => "83c3187f-84f6-4da7-8206-73af5aca7cc8", "_aj_symbol_keys" => [] }],
            queue: "default",
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
