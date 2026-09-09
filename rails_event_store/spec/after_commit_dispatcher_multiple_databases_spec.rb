# frozen_string_literal: true

require "spec_helper"

module RailsEventStore
  ::RSpec.describe AfterCommitDispatcher do
    specify "watching the connection that owns the business transaction schedules after its commit" do
      event_store =
        event_store_dispatching_with(
          AfterCommitDispatcher.new(
            scheduler: ActiveJobScheduler.new(serializer: RubyEventStore::Serializers::YAML),
            model: AppRecord,
          ),
        )
      event_store.subscribe(MultiDbAsyncHandler, to: [MultiDbOrderPlaced])

      AppRecord.transaction do
        AppRecord.lease_connection.execute("INSERT INTO orders (number) VALUES ('42')")
        event_store.publish(MultiDbOrderPlaced.new(data: { order_id: 42 }))

        expect(MultiDbAsyncHandler.queued).to be_nil
      end

      expect(MultiDbAsyncHandler.queued).not_to be_nil
    end

    specify "watching the connection that owns the business transaction takes the job back on rollback" do
      event_store =
        event_store_dispatching_with(
          AfterCommitDispatcher.new(
            scheduler: ActiveJobScheduler.new(serializer: RubyEventStore::Serializers::YAML),
            model: AppRecord,
          ),
        )
      event_store.subscribe(MultiDbAsyncHandler, to: [MultiDbOrderPlaced])

      AppRecord.transaction do
        AppRecord.lease_connection.execute("INSERT INTO orders (number) VALUES ('42')")
        event_store.publish(MultiDbOrderPlaced.new(data: { order_id: 42 }))
        raise ::ActiveRecord::Rollback
      end

      expect(MultiDbAsyncHandler.queued).to be_nil
    end

    specify "default ActiveRecord::Base does not see a business transaction opened on another connection" do
      event_store =
        event_store_dispatching_with(
          AfterCommitDispatcher.new(scheduler: ActiveJobScheduler.new(serializer: RubyEventStore::Serializers::YAML)),
        )
      event_store.subscribe(MultiDbAsyncHandler, to: [MultiDbOrderPlaced])

      AppRecord.transaction do
        event_store.publish(MultiDbOrderPlaced.new(data: { order_id: 42 }))

        expect(MultiDbAsyncHandler.queued).not_to be_nil
      end
    end

    specify "watching the event store connection does not see a business transaction either" do
      event_store =
        event_store_dispatching_with(
          AfterCommitDispatcher.new(
            scheduler: ActiveJobScheduler.new(serializer: RubyEventStore::Serializers::YAML),
            model: EventsRecord,
          ),
        )
      event_store.subscribe(MultiDbAsyncHandler, to: [MultiDbOrderPlaced])

      AppRecord.transaction do
        event_store.publish(MultiDbOrderPlaced.new(data: { order_id: 42 }))

        expect(MultiDbAsyncHandler.queued).not_to be_nil
      end
    end

    specify "watching the event store connection leaves the job scheduled after a business rollback" do
      event_store =
        event_store_dispatching_with(
          AfterCommitDispatcher.new(
            scheduler: ActiveJobScheduler.new(serializer: RubyEventStore::Serializers::YAML),
            model: EventsRecord,
          ),
        )
      event_store.subscribe(MultiDbAsyncHandler, to: [MultiDbOrderPlaced])

      AppRecord.transaction do
        AppRecord.lease_connection.execute("INSERT INTO orders (number) VALUES ('42')")
        event_store.publish(MultiDbOrderPlaced.new(data: { order_id: 42 }))
        raise ::ActiveRecord::Rollback
      end

      expect(MultiDbAsyncHandler.queued).not_to be_nil
      expect(AppRecord.lease_connection.select_value("SELECT COUNT(*) FROM orders")).to eq(0)
      expect(event_store.read.of_type([MultiDbOrderPlaced]).count).to eq(1)
    end

    def event_store_dispatching_with(dispatcher)
      Client.new(
        repository:
          RubyEventStore::ActiveRecord::EventRepository.new(
            model_factory: RubyEventStore::ActiveRecord::WithAbstractBaseClass.new(EventsRecord),
            serializer: RubyEventStore::Serializers::YAML,
          ),
        message_broker:
          RubyEventStore::Broker.new(
            dispatcher: RubyEventStore::ComposedDispatcher.new(dispatcher, RubyEventStore::SyncScheduler.new),
          ),
      )
    end

    before do
      AppRecord.establish_connection(adapter: "sqlite3", database: ":memory:")
      AppRecord.lease_connection.create_table(:orders, force: true) { |t| t.string(:number) }

      EventsRecord.establish_connection(adapter: "sqlite3", database: ":memory:")
      Migrator.new(
        File.expand_path(
          "../../ruby_event_store-active_record/lib/ruby_event_store/active_record/generators/templates",
          __dir__,
        ),
      ).run_migration("create_event_store_events", connection: EventsRecord.lease_connection)

      MultiDbAsyncHandler.reset
    end

    after do
      AppRecord.remove_connection
      EventsRecord.remove_connection
    end

    class AppRecord < ActiveRecord::Base
      self.abstract_class = true
    end

    class EventsRecord < ActiveRecord::Base
      self.abstract_class = true
    end

    MultiDbOrderPlaced = Class.new(RubyEventStore::Event)

    class MultiDbAsyncHandler < ActiveJob::Base
      @@queued = nil
      def self.reset = @@queued = nil
      def self.queued = @@queued
      def self.perform_later(record) = @@queued = record
    end
  end
end
