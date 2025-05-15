# frozen_string_literal: true

require "spec_helper"

module RubyEventStore
  ::RSpec.describe SidekiqScheduler do
    it_behaves_like 'scheduler',
                    SidekiqScheduler.new(serializer: Serializers::YAML)
    it_behaves_like 'scheduler', SidekiqScheduler.new(serializer: JSON)

    describe "#verify" do
      let(:scheduler) { SidekiqScheduler.new(serializer: JSON) }
      let(:proper_handler) { Class.new { include Sidekiq::Worker } }

      specify { expect(scheduler.verify(proper_handler)).to be(true) }

      specify "Sidekiq::Job::Setter is also acceptable" do
        expect(scheduler.verify(proper_handler.set({}))).to be(true)
      end

      specify { expect(scheduler.verify(Class.new)).to be(false) }

      specify { expect(scheduler.verify(Sidekiq::Worker)).to be(false) }

      specify { expect(scheduler.verify(Object.new)).to be(false) }
    end

    describe "#call" do
      before do
        MyAsyncHandler.reset
        Sidekiq::Worker.clear_all
      end

      let(:event) do
        TimeEnrichment.with(
          Event.new(event_id: "83c3187f-84f6-4da7-8206-73af5aca7cc8"),
          timestamp: Time.utc(2019, 9, 30)
        )
      end
      let(:record) { Mappers::Default.new.event_to_record(event) }

      let(:scheduler) { SidekiqScheduler.new(serializer: Serializers::YAML) }

      specify do
        scheduler.call(MyAsyncHandler, record)

        enqueued_jobs = MyAsyncHandler.jobs
        expect(enqueued_jobs.size).to eq(1)
        expect(enqueued_jobs[0]).to include(
          {
            "class" => "RubyEventStore::MyAsyncHandler",
            "args" => [
              {
                "event_id" => "83c3187f-84f6-4da7-8206-73af5aca7cc8",
                "event_type" => "RubyEventStore::Event",
                "data" => "--- {}\n",
                "metadata" => "--- {}\n",
                "timestamp" => "2019-09-30T00:00:00.000000Z",
                "valid_at" => "2019-09-30T00:00:00.000000Z"
              }
            ],
            "queue" => "default"
          }
        )
      end

      specify "pass Sidekiq::Job::Setter" do
        scheduler.call(MyAsyncHandler.set({ queue: "non-default" }), record)

        enqueued_jobs = MyAsyncHandler.jobs
        expect(enqueued_jobs.size).to eq(1)
        expect(enqueued_jobs[0]).to include(
          {
            "class" => "RubyEventStore::MyAsyncHandler",
            "args" => [
              {
                "event_id" => "83c3187f-84f6-4da7-8206-73af5aca7cc8",
                "event_type" => "RubyEventStore::Event",
                "data" => "--- {}\n",
                "metadata" => "--- {}\n",
                "timestamp" => "2019-09-30T00:00:00.000000Z",
                "valid_at" => "2019-09-30T00:00:00.000000Z"
              }
            ],
            "queue" => "non-default"
          }
        )
      end

      specify "JSON compatible args with stringified keys" do
        expect(MyAsyncHandler).to receive(:perform_async).with(
          {
            "event_id" => "83c3187f-84f6-4da7-8206-73af5aca7cc8",
            "event_type" => "RubyEventStore::Event",
            "data" => "--- {}\n",
            "metadata" => "--- {}\n",
            "timestamp" => "2019-09-30T00:00:00.000000Z",
            "valid_at" => "2019-09-30T00:00:00.000000Z"
          }
        )

        scheduler.call(MyAsyncHandler, record)
      end

      specify "with Redis involved", :redis do
        scheduler.call(MyAsyncHandler, record)
        sidekiq_processor.send :process_one
        expect(MyAsyncHandler.received).to match(
          {
            "event_id" => "83c3187f-84f6-4da7-8206-73af5aca7cc8",
            "event_type" => "RubyEventStore::Event",
            "data" => "--- {}\n",
            "metadata" => "--- {}\n",
            "timestamp" => "2019-09-30T00:00:00.000000Z",
            "valid_at" => "2019-09-30T00:00:00.000000Z"
          }
        )
      end
    end

    private

    def sidekiq_processor
      options =
        case Sidekiq::VERSION.to_i
        when 5
          Struct.new(:options).new({ queues: ["default"] })
        when 6
          opts = Sidekiq
          opts[:queues] = ["default"]
          opts[:fetch] = Sidekiq::BasicFetch.new(opts)
          opts
        when 7
          Sidekiq::Config.new.default_capsule
        else
          skip "Unsupported Sidekiq version"
        end
      processor = Sidekiq::Processor.new(options)
      processor.logger.level = Logger::WARN
      processor
    end

    class MyAsyncHandler
      include Sidekiq::Worker

      def self.reset
        Thread.current[:received] = nil
      end
      def self.received
        Thread.current[:received]
      end
      def perform(event)
        Thread.current[:received] = event
      end
    end
  end
end
