# frozen_string_literal: true

require "spec_helper"

# Truncate, soft delete and retention are not meant for aggregate streams: the repository takes
# the aggregate version from the number of events it reads, so once some are hidden that version
# is too low for good. Closing an aggregate is a tombstone.
module AggregateRoot
  ::RSpec.describe Repository do
    let(:event_store) do
      RubyEventStore::Client.new(
        repository: RubyEventStore::StreamMetadataAwareRepository.new(RubyEventStore::InMemoryRepository.new),
      )
    end
    let(:stream_name) { "Order$#{SecureRandom.uuid}" }
    let(:repository) { AggregateRoot::Repository.new(event_store) }
    let(:order_klass) do
      Class.new do
        include AggregateRoot

        def create
          apply Orders::Events::OrderCreated.new
        end

        def expire
          apply Orders::Events::OrderExpired.new
        end

        attr_reader :status

        on Orders::Events::OrderCreated do |_event|
          @status = :created
        end

        on Orders::Events::OrderExpired do |_event|
          @status = :expired
        end
      end
    end

    before do
      repository.with_aggregate(order_klass.new, stream_name, &:create)
      repository.with_aggregate(order_klass.new, stream_name, &:expire)
    end

    specify "store fails for good after the aggregate stream was truncated" do
      event_store.truncate_stream(stream_name, before: 1)

      2.times do
        expect { repository.with_aggregate(order_klass.new, stream_name, &:expire) }.to raise_error(
          RubyEventStore::WrongExpectedEventVersion,
        )
      end
    end

    specify "store fails for good after the aggregate stream was soft deleted" do
      event_store.soft_delete_stream(stream_name)

      2.times do
        expect { repository.with_aggregate(order_klass.new, stream_name, &:create) }.to raise_error(
          RubyEventStore::WrongExpectedEventVersion,
        )
      end
    end

    specify "store is refused after a tombstone, while load still sees the full history" do
      event_store.tombstone_stream(stream_name)

      order = repository.load(order_klass.new, stream_name)
      expect(order).to have_attributes(status: :expired, version: 1)

      order.expire
      expect { repository.store(order, stream_name) }.to raise_error(RubyEventStore::StreamTombstoned)
      expect(event_store.read.stream(stream_name).count).to eq(2)
    end
  end
end
