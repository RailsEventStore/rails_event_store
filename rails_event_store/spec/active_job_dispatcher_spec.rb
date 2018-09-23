require 'spec_helper'
require 'active_job'
require 'ruby_event_store'
require 'ruby_event_store/spec/dispatcher_lint'

module RailsEventStore
  RSpec.describe ActiveJobDispatcher do
    it_behaves_like :dispatcher, ActiveJobDispatcher.new

    around do |example|
      with_queue_adapter(ActiveJob::Base) do
        begin
          original_logger = ActiveJob::Base.logger
          ActiveJob::Base.logger = nil
          example.run
        ensure
          ActiveJob::Base.logger = original_logger
        end
      end
    end

    before(:each) do
      CallableHandler.reset
      MyAsyncHandler.reset
    end

    let!(:event) { RailsEventStore::Event.new(event_id: "83c3187f-84f6-4da7-8206-73af5aca7cc8") }
    let!(:serialized_event)  { RubyEventStore::Mappers::Default.new.event_to_serialized_record(event) }

    it "verification" do
      expect(ActiveJobDispatcher.new.verify(MyAsyncHandler)).to eq(true)
      expect(ActiveJobDispatcher.new.verify(ActiveJob::Base)).to eq(false)
      expect(ActiveJobDispatcher.new.verify(Object.new)).to eq(false)
    end

    it "builds async proxy for ActiveJob::Base ancestors" do
      expect_to_have_enqueued_job(MyAsyncHandler) do
        ActiveJobDispatcher.new.call(MyAsyncHandler, event, serialized_event)
      end
      expect(MyAsyncHandler.received).to be_nil
      perform_enqueued_jobs(MyAsyncHandler.queue_adapter)
      expect(MyAsyncHandler.received).to eq({
        "event_id"        => "83c3187f-84f6-4da7-8206-73af5aca7cc8",
        "data"            => "--- {}\n",
        "metadata"        => "--- {}\n",
        "event_type"      => "RubyEventStore::Event",
        "_aj_symbol_keys" => ["event_id", "data", "metadata", "event_type"]
      })
    end

    it "async proxy for defined adapter enqueue job immediately when no transaction is open" do
      dispatcher = ActiveJobDispatcher.new(proxy_strategy: AsyncProxyStrategy::AfterCommit.new)
      expect_to_have_enqueued_job(MyAsyncHandler) do
        dispatcher.call(MyAsyncHandler, event, serialized_event)
      end
      expect(MyAsyncHandler.received).to be_nil
      perform_enqueued_jobs(MyAsyncHandler.queue_adapter)
      expect(MyAsyncHandler.received).to eq({
          "event_id"        => "83c3187f-84f6-4da7-8206-73af5aca7cc8",
          "data"            => "--- {}\n",
          "metadata"        => "--- {}\n",
          "event_type"      => "RubyEventStore::Event",
          "_aj_symbol_keys" => ["event_id", "data", "metadata", "event_type"]
      })
    end

    it "async proxy for defined adapter enqueue job only after transaction commit" do
      dispatcher = ActiveJobDispatcher.new(proxy_strategy: AsyncProxyStrategy::AfterCommit.new)
      expect_to_have_enqueued_job(MyAsyncHandler) do
        ActiveRecord::Base.transaction do
          expect_no_enqueued_job do
            dispatcher.call(MyAsyncHandler, event, serialized_event)
          end
        end
      end
      expect(MyAsyncHandler.received).to be_nil
      perform_enqueued_jobs(MyAsyncHandler.queue_adapter)
      expect(MyAsyncHandler.received).to eq({
          "event_id"        => "83c3187f-84f6-4da7-8206-73af5aca7cc8",
          "data"            => "--- {}\n",
          "metadata"        => "--- {}\n",
          "event_type"      => "RubyEventStore::Event",
          "_aj_symbol_keys" => ["event_id", "data", "metadata", "event_type"]
      })
    end

    it "async proxy for defined adapter do not enqueue job after transaction rollback" do
      dispatcher = ActiveJobDispatcher.new(proxy_strategy: AsyncProxyStrategy::AfterCommit.new)
      expect_no_enqueued_job(MyAsyncHandler) do
        ActiveRecord::Base.transaction do
          dispatcher.call(MyAsyncHandler, event, serialized_event)
          raise ActiveRecord::Rollback
        end
      end
      perform_enqueued_jobs(MyAsyncHandler.queue_adapter)
      expect(MyAsyncHandler.received).to be_nil
    end

    it "async proxy for defined adapter does not enqueue job after transaction rollback (with raises)" do
      was = ActiveRecord::Base.raise_in_transactional_callbacks
      begin
        ActiveRecord::Base.raise_in_transactional_callbacks = true

        dispatcher = ActiveJobDispatcher.new(proxy_strategy: AsyncProxyStrategy::AfterCommit.new)
        expect_no_enqueued_job(MyAsyncHandler) do
          ActiveRecord::Base.transaction do
            dispatcher.call(MyAsyncHandler, event, serialized_event)
            raise ActiveRecord::Rollback
          end
        end
        perform_enqueued_jobs(MyAsyncHandler.queue_adapter)
        expect(MyAsyncHandler.received).to be_nil
      ensure
        ActiveRecord::Base.raise_in_transactional_callbacks = was
      end
    end if ActiveRecord::Base.respond_to?(:raise_in_transactional_callbacks)

    it "async proxy for defined adapter enqueue job only after top-level transaction (nested is not new) commit" do
      dispatcher = ActiveJobDispatcher.new(proxy_strategy: AsyncProxyStrategy::AfterCommit.new)
      expect_to_have_enqueued_job(MyAsyncHandler) do
        ActiveRecord::Base.transaction do
          expect_no_enqueued_job do
            ActiveRecord::Base.transaction(requires_new: false) do
              dispatcher.call(MyAsyncHandler, event, serialized_event)
            end
          end
        end
      end
      expect(MyAsyncHandler.received).to be_nil
      perform_enqueued_jobs(MyAsyncHandler.queue_adapter)
      expect(MyAsyncHandler.received).to eq({
          "event_id"        => "83c3187f-84f6-4da7-8206-73af5aca7cc8",
          "data"            => "--- {}\n",
          "metadata"        => "--- {}\n",
          "event_type"      => "RubyEventStore::Event",
          "_aj_symbol_keys" => ["event_id", "data", "metadata", "event_type"]
      })
    end

    it "async proxy for defined adapter enqueue job only after top-level transaction commit" do
      dispatcher = ActiveJobDispatcher.new(proxy_strategy: AsyncProxyStrategy::AfterCommit.new)
      expect_to_have_enqueued_job(MyAsyncHandler) do
        ActiveRecord::Base.transaction do
          expect_no_enqueued_job do
            ActiveRecord::Base.transaction(requires_new: true) do
              dispatcher.call(MyAsyncHandler, event, serialized_event)
            end
          end
        end
      end
      expect(MyAsyncHandler.received).to be_nil
      perform_enqueued_jobs(MyAsyncHandler.queue_adapter)
      expect(MyAsyncHandler.received).to eq({
          "event_id"        => "83c3187f-84f6-4da7-8206-73af5aca7cc8",
          "data"            => "--- {}\n",
          "metadata"        => "--- {}\n",
          "event_type"      => "RubyEventStore::Event",
          "_aj_symbol_keys" => ["event_id", "data", "metadata", "event_type"]
      })
    end

    it "async proxy for defined adapter do not enqueue job after nested transaction rollback" do
      dispatcher = ActiveJobDispatcher.new(proxy_strategy: AsyncProxyStrategy::AfterCommit.new)
      expect_no_enqueued_job(MyAsyncHandler) do
        ActiveRecord::Base.transaction do
          expect_no_enqueued_job do
            ActiveRecord::Base.transaction(requires_new: true) do
              dispatcher.call(MyAsyncHandler, event, serialized_event)
              raise ActiveRecord::Rollback
            end
          end
        end
      end
      perform_enqueued_jobs(MyAsyncHandler.queue_adapter)
      expect(MyAsyncHandler.received).to be_nil
    end

    def with_queue_adapter(job, queue_adapter = :test, &proc)
      raise unless block_given?
      adapter = job.queue_adapter
      job.queue_adapter = queue_adapter
      yield
      job.queue_adapter = adapter
    end

    def expect_no_enqueued_job(job = ActiveJob::Base, &proc)
      raise unless block_given?
      yield
      expect(job.queue_adapter.enqueued_jobs).to be_empty
    end

    def expect_to_have_enqueued_job(job, &proc)
      raise unless block_given?
      yield
      found = job.queue_adapter.enqueued_jobs.select{|enqueued| enqueued[:job] == job}.count
      expect(found).to eq(1)
    end

    def perform_enqueued_jobs(queue_adapter)
      queue_adapter.enqueued_jobs.each do |enqueued|
        enqueued[:job].perform_now(*enqueued[:args])
      end
    end

    private
    class CallableHandler
      @@received = nil
      def self.reset
        @@received = nil
      end
      def self.received
        @@received
      end
      def call(event)
        @@received = event
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
