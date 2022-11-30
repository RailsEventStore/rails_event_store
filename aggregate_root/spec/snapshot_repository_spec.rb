# frozen_string_literal: true

require 'spec_helper'

module AggregateRoot
  RSpec.describe SnapshotRepository do
    let(:event_store) { RubyEventStore::Client.new(repository: RubyEventStore::InMemoryRepository.new, mapper: RubyEventStore::Mappers::NullMapper.new) }
    let(:uuid) { SecureRandom.uuid }
    let(:stream_name) { "Order$#{uuid}" }
    let(:repository) { AggregateRoot::SnapshotRepository.new(event_store) }
    let(:order_klass) do
      class Order
        include AggregateRoot

        def initialize(uuid)
          @status = :draft
          @uuid = uuid
        end

        def create
          apply Orders::Events::OrderCreated.new
        end

        def expire
          apply Orders::Events::OrderExpired.new
        end

        attr_accessor :status

        private

        def apply_order_created(_event)
          @status = :created
        end

        def apply_order_expired(_event)
          @status = :expired
        end
      end

      Order
    end

    specify do
      order = order_klass.new(uuid)

      order.create

      repository.store(order, stream_name)

      expect_certain_event_types(stream_name, 'Orders::Events::OrderCreated')
      expect_snapshot(stream_name)
    end

    specify do
      order = order_klass.new(uuid)

      order.create

      repository = AggregateRoot::SnapshotRepository.new(event_store, 2)
      repository.store(order, stream_name)

      expect_certain_event_types(stream_name, 'Orders::Events::OrderCreated')
      expect_snapshot(stream_name)

      order.expire
      repository.store(order, stream_name)
      expect_certain_event_types(stream_name, 'Orders::Events::OrderCreated', 'Orders::Events::OrderExpired')
      expect_snapshot(stream_name)
    end

    specify do
      order = order_klass.new(uuid)

      order.create
      order.expire

      repository = AggregateRoot::SnapshotRepository.new(event_store)
      repository.store(order, stream_name)

      order_from_snapshot = repository.load(order_klass.new(uuid), stream_name)

      expect(order.status).to eq(order_from_snapshot.status)
      expect(order_from_snapshot.status).to eq(:expired)
    end

    private

    def expect_certain_event_types(stream_name, *event_types)
      expect(event_store.read.stream(stream_name).map(&:event_type))
        .to eq(event_types)
    end

    def expect_snapshot(stream_name)
      expect(event_store.read.stream("#{stream_name}_snapshots").map(&:event_type))
        .to eq(
              ['AggregateRoot::SnapshotRepository::Snapshot']
            )
    end
  end
end