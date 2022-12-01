# frozen_string_literal: true

require 'spec_helper'

module AggregateRoot
  class ReadsStatsRepository < SimpleDelegator
    def initialize(repository)
      super(repository)
      @records_read = 0
    end

    attr_reader :records_read

    def reset_read_stats
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
    let(:reporting_repository) { ReadsStatsRepository.new(RubyEventStore::InMemoryRepository.new) }
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

        def apply_order_created(_)
          @status = :created
        end

        def apply_order_expired(_)
          @status = :expired
        end

        def apply_order_canceled(_)
          @status = :canceled
        end
      end

      Order
    end

    specify 'initialization' do
      expect { AggregateRoot::SnapshotRepository.new(event_store, 0) }
        .to raise_error(ArgumentError, "interval must be greater than 0")
    end

    specify 'storing snapshot on each change' do
      order = order_klass.new(uuid)
      repository = AggregateRoot::SnapshotRepository.new(event_store)
      allow(event_store).to receive(:publish)

      order.apply(order_created)
      repository.store(order, stream_name)
      expect(event_store).to have_received(:publish).with(
        [order_created],
        stream_name: stream_name,
        expected_version: -1
      )
      expect_snapshot(stream_name, order_created.event_id, 0, Marshal.dump(order))
    end

    specify 'storing snapshot with given interval' do
      order = order_klass.new(uuid)
      repository = AggregateRoot::SnapshotRepository.new(event_store, 2)
      allow(event_store).to receive(:publish)

      order.apply(order_created)
      repository.store(order, stream_name)
      expect(event_store).to have_received(:publish).with(
        [order_created],
        stream_name: stream_name,
        expected_version: -1
      )
      expect_no_snapshot(stream_name)

      order.apply(order_expired)
      repository.store(order, stream_name)
      expect(event_store).to have_received(:publish).with(
        [order_expired],
        stream_name: stream_name,
        expected_version: 0
      )
      expect_snapshot(stream_name, order_expired.event_id, 1, Marshal.dump(order))
    end

    specify "restoring snapshot" do
      order = order_klass.new(uuid)
      repository = AggregateRoot::SnapshotRepository.new(event_store)

      order.apply(order_created)
      event_store.publish(order_created, stream_name: stream_name)
      order.apply(order_canceled)
      event_store.publish(order_canceled, stream_name: stream_name)
      reporting_repository.reset_read_stats
      order_from_snapshot = repository.load(order_klass.new(uuid), stream_name)
      expect(order_from_snapshot.status).to eq(:canceled)
      expect(order_from_snapshot.version).to eq(1)
      expect(reporting_repository.records_read).to eq(2)

      event_store.publish(
        AggregateRoot::SnapshotRepository::Snapshot.new(
          data: { marshal: Marshal.dump(order), last_event_id: order_canceled.event_id, version: 1 }
        ),
        stream_name: "#{stream_name}_snapshots"
      )
      reporting_repository.reset_read_stats
      order_from_snapshot = repository.load(order_klass.new(uuid), stream_name)
      expect(order_from_snapshot.status).to eq(:canceled)
      expect(order_from_snapshot.version).to eq(1)
      expect(reporting_repository.records_read).to eq(1)

      order.apply(order_expired)
      event_store.publish(order_expired, stream_name: stream_name)
      reporting_repository.reset_read_stats
      order_from_snapshot = repository.load(order_klass.new(uuid), stream_name)
      expect(order_from_snapshot.status).to eq(:expired)
      expect(order_from_snapshot.version).to eq(2)
      expect(reporting_repository.records_read).to eq(2)
    end

    private

    def expect_certain_event_types(stream_name, *event_types)
      expect(event_store.read.stream(stream_name).map(&:event_type))
        .to eq(event_types)
    end

    def expect_snapshot(stream_name, last_event_id, version, marshal)
      expect(event_store).to have_received(:publish).with(
        have_attributes(data: hash_including(last_event_id: last_event_id, version: version, marshal: marshal)),
        stream_name: "#{stream_name}_snapshots"
      )
    end

    def expect_no_snapshot(stream_name)
      expect(event_store).not_to have_received(:publish).with(
        kind_of(AggregateRoot::SnapshotRepository::Snapshot),
        stream_name: "#{stream_name}_snapshots"
      )
    end
  end
end