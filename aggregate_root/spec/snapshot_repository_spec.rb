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

        def cancel
          apply Orders::Events::OrderCanceled.new
        end

        def expire
          apply Orders::Events::OrderExpired.new
        end

        attr_accessor :status

        private

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

    specify "storing snapshots" do
      order = order_klass.new(uuid)
      repository = AggregateRoot::SnapshotRepository.new(event_store, 2)

      order.create
      repository.store(order, stream_name)
      expect_certain_event_types(stream_name, 'Orders::Events::OrderCreated')
      expect_no_snapshot(stream_name)

      order.cancel
      repository.store(order, stream_name)
      expect_certain_event_types(
        stream_name,
        'Orders::Events::OrderCreated', 'Orders::Events::OrderCanceled'
      )
      expect_no_snapshot(stream_name)

      order.expire
      repository.store(order, stream_name)
      expect_certain_event_types(
        stream_name,
        'Orders::Events::OrderCreated', 'Orders::Events::OrderCanceled', 'Orders::Events::OrderExpired'
      )
      expect_snapshot(stream_name)
    end

    specify "restoring snapshot" do
      order = order_klass.new(uuid)
      repository = AggregateRoot::SnapshotRepository.new(event_store)
      order.create
      order.expire
      repository.store(order, stream_name)

      expect_snapshot(stream_name)
      reporting_repository.reset_read_stats
      order_from_snapshot = repository.load(order_klass.new(uuid), stream_name)
      expect(order.status).to eq(order_from_snapshot.status)
      expect(order_from_snapshot.status).to eq(:expired)
      expect(reporting_repository.records_read).to eq(1)
    end

    private

    def expect_certain_event_types(stream_name, *event_types)
      expect(event_store.read.stream(stream_name).map(&:event_type))
        .to eq(event_types)
    end

    def expect_snapshot(stream_name)
      expect_certain_event_types("#{stream_name}_snapshots", 'AggregateRoot::SnapshotRepository::Snapshot')
    end

    def expect_no_snapshot(stream_name)
      expect_certain_event_types("#{stream_name}_snapshots")
    end
  end
end