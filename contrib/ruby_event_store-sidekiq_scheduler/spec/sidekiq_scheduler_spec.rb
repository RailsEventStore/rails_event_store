require "spec_helper"
require "ruby_event_store/spec/scheduler_lint"
require "sidekiq/testing"
require "sidekiq/processor"

module RubyEventStore
  RSpec.describe SidekiqScheduler do
    before(:each) { MyAsyncHandler.reset }

    it_behaves_like :scheduler, SidekiqScheduler.new(serializer: RubyEventStore::Serializers::YAML)
    it_behaves_like :scheduler, SidekiqScheduler.new(serializer: RubyEventStore::NULL)

    let(:event) do
      TimeEnrichment.with(Event.new(event_id: "83c3187f-84f6-4da7-8206-73af5aca7cc8"), timestamp: Time.utc(2019, 9, 30))
    end
    let(:record) { RubyEventStore::Mappers::Default.new.event_to_record(event) }
    let(:redis_url) { ENV["REDIS_URL"] }
    let(:redis) { Redis.new(url: redis_url) }

    describe "#verify" do
      specify do
        scheduler = SidekiqScheduler.new(serializer: RubyEventStore::NULL)
        proper_handler = Class.new { include Sidekiq::Worker }

        expect(scheduler.verify(proper_handler)).to eq(true)
      end

      specify do
        scheduler = SidekiqScheduler.new(serializer: RubyEventStore::NULL)
        some_class = Class.new

        expect(scheduler.verify(some_class)).to eq(false)
      end

      specify do
        scheduler = SidekiqScheduler.new(serializer: RubyEventStore::NULL)

        expect(scheduler.verify(Sidekiq::Worker)).to eq(false)
      end

      specify do
        scheduler = SidekiqScheduler.new(serializer: RubyEventStore::NULL)
        expect(scheduler.verify(Object.new)).to eq(false)
      end
    end

    describe "#call" do
      specify do
        scheduler = SidekiqScheduler.new(serializer: RubyEventStore::Serializers::YAML)

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

      specify "JSON compatible args with stringified keys" do
        scheduler = SidekiqScheduler.new(serializer: RubyEventStore::Serializers::YAML)
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

      specify 'with Redis involved' do
        scheduler = SidekiqScheduler.new(serializer: RubyEventStore::Serializers::YAML)
        Sidekiq::Testing.disable! do
          scheduler.call(MyAsyncHandler, record)
        end
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
      options = case Sidekiq::VERSION.to_i
             when 5
               Struct.new(:options).new({ queues: ['default'] })
             when 6
               opts = Sidekiq
               opts[:queues] = ['default']
               opts[:fetch] = Sidekiq::BasicFetch.new(opts)
               opts
             else
               skip 'Unsupported Sidekiq version'
             end
      Sidekiq::Processor.new(options)
    end

    class MyAsyncHandler
      include Sidekiq::Worker

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
