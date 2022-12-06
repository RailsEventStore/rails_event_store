# frozen_string_literal: true

require 'spec_helper'

module AggregateRoot
  class ReadingStatsRepository < SimpleDelegator
    def initialize(repository)
      super(repository)
      @records_read = 0
    end

    attr_reader :records_read

    def reset_records_read
      @records_read = 0
    end

    def read(spec)
      @records_read += count(spec)
      super
    end
  end

  RSpec.describe SnapshotRepository do
    let(:event_store) do
      RubyEventStore::Client.new(
        repository: reporting_repository,
        mapper: RubyEventStore::Mappers::NullMapper.new
      )
    end
    let(:reporting_repository) { ReadingStatsRepository.new(RubyEventStore::InMemoryRepository.new) }
    let(:uuid) { SecureRandom.uuid }
    let(:stream_name) { "Order$#{uuid}" }
    let(:repository) { AggregateRoot::SnapshotRepository.new(event_store) }
    let(:order_created) { Orders::Events::OrderCreated.new }
    let(:order_canceled) { Orders::Events::OrderCanceled.new }
    let(:order_expired) { Orders::Events::OrderExpired.new }

    let(:order_klass) do
      class Order
        include AggregateRoot

        def initialize(uuid)
          @status = :draft
          @uuid = uuid
        end

        attr_accessor :status

        on Orders::Events::OrderCreated do |_|
          @status = :created
        end

        on Orders::Events::OrderExpired do |_|
          @status = :expired
        end

        on Orders::Events::OrderCanceled do |_|
          @status = :canceled
        end
      end

      Order
    end

    specify 'initialization' do
      expect { AggregateRoot::SnapshotRepository.new(event_store, 0) }
        .to raise_error(ArgumentError, "interval must be greater than 0")
      expect { AggregateRoot::SnapshotRepository.new(event_store, 'not integer') }
        .to raise_error(ArgumentError, "interval must be an Integer")
    end

    specify 'storing snapshot' do
      order = order_klass.new(uuid)
      repository = AggregateRoot::SnapshotRepository.new(event_store, 1)
      allow(event_store).to receive(:publish)

      order.apply(order_created)
      repository.store(order, stream_name)
      expect(event_store).to have_received(:publish).with(
        [order_created],
        stream_name: stream_name,
        expected_version: -1
      )
      expect_snapshot(order_created.event_id, 0, Marshal.dump(order))
    end

    specify 'storing snapshot with given interval' do
      order = order_klass.new(uuid)
      repository = AggregateRoot::SnapshotRepository.new(event_store, 2)
      allow(event_store).to receive(:publish)

      order.apply(order_created)
      repository.store(order, stream_name)
      expect_no_snapshot

      order.apply(order_expired)
      repository.store(order, stream_name)
      expect_snapshot(order_expired.event_id, 1, Marshal.dump(order))
    end

    specify "restoring snapshot" do
      order = order_klass.new(uuid)
      repository = AggregateRoot::SnapshotRepository.new(event_store)

      apply_and_publish(order, order_created, order_canceled)
      expect_n_records_read(2) do
        order_from_snapshot = repository.load(order_klass.new(uuid), stream_name)
        expect(order_from_snapshot.status).to eq(:canceled)
        expect(order_from_snapshot.version).to eq(1)
      end

      publish_snapshot(order, order_canceled.event_id, 1)
      expect_n_records_read(1) do
        order_from_snapshot = repository.load(order_klass.new(uuid), stream_name)
        expect(order_from_snapshot.status).to eq(:canceled)
        expect(order_from_snapshot.version).to eq(1)
      end

      apply_and_publish(order, order_expired)
      expect_n_records_read(2) do
        order_from_snapshot = repository.load(order_klass.new(uuid), stream_name)
        expect(order_from_snapshot.status).to eq(:expired)
        expect(order_from_snapshot.version).to eq(2)
      end
    end

    private

    def expect_n_records_read(n, &block)
      reporting_repository.reset_records_read
      yield block
      expect(reporting_repository.records_read).to eq(n)
    end

    def apply_and_publish(order, *events)
      events.each do |e|
        order.apply(e)
        event_store.publish(e, stream_name: stream_name)
      end
    end

    def publish_snapshot(order, last_event_id, version)
      event_store.publish(
        AggregateRoot::SnapshotRepository::Snapshot.new(
          data: { marshal: Marshal.dump(order), last_event_id: last_event_id, version: version }
        ),
        stream_name: "#{stream_name}_snapshots"
      )
    end

    def expect_snapshot(last_event_id, version, marshal)
      expect(event_store).to have_received(:publish).with(
        have_attributes(data: hash_including(last_event_id: last_event_id, version: version, marshal: marshal)),
        stream_name: "#{stream_name}_snapshots"
      )
    end

    def expect_no_snapshot
      expect(event_store).not_to have_received(:publish).with(
        kind_of(AggregateRoot::SnapshotRepository::Snapshot),
        stream_name: "#{stream_name}_snapshots"
      )
    end
  end
end