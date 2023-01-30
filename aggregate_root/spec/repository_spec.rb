# frozen_string_literal: true

require "spec_helper"

module AggregateRoot
  ::RSpec.describe Repository do
    let(:event_store) { RubyEventStore::Client.new }
    let(:uuid) { SecureRandom.uuid }
    let(:stream_name) { "Order$#{uuid}" }
    let(:repository) { AggregateRoot::Repository.new(event_store) }
    let(:order_klass) do
      Class.new do
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
    end

    describe "#load" do
      specify do
        event_store.publish(Orders::Events::OrderCreated.new, stream_name: stream_name)
        order = repository.load(order_klass.new(uuid), stream_name)

        expect(order.status).to eq(:created)
      end

      specify do
        event_store.publish(Orders::Events::OrderCreated.new, stream_name: stream_name)
        order = repository.load(order_klass.new(uuid), stream_name)

        expect(order.unpublished_events.to_a).to be_empty
      end

      specify do
        event_store.publish(Orders::Events::OrderCreated.new, stream_name: stream_name)
        event_store.publish(Orders::Events::OrderExpired.new, stream_name: stream_name)
        order = repository.load(order_klass.new(uuid), stream_name)

        expect(order.version).to eq(1)
      end

      specify do
        event_store.publish(Orders::Events::OrderCreated.new, stream_name: stream_name)
        event_store.publish(Orders::Events::OrderExpired.new, stream_name: "dummy")
        order = repository.load(order_klass.new(uuid), stream_name)

        expect(order.version).to eq(0)
      end
    end

    describe "#store" do
      specify do
        order_created = Orders::Events::OrderCreated.new
        order_expired = Orders::Events::OrderExpired.new
        order = order_klass.new(uuid)
        order.apply(order_created)
        order.apply(order_expired)
        allow(event_store).to receive(:publish)

        repository.store(order, stream_name)

        expect(order.unpublished_events.to_a).to be_empty
        expect(event_store).to have_received(:publish).with(
          [order_created, order_expired],
          stream_name: stream_name,
          expected_version: -1
        )
        expect(event_store).not_to have_received(:publish).with(kind_of(Enumerator), any_args)
      end

      it "updates aggregate stream position and uses it in subsequent publish call as expected_version" do
        order_created = Orders::Events::OrderCreated.new
        order_expired = Orders::Events::OrderExpired.new
        order = order_klass.new(uuid)
        order.apply(order_created)
        allow(event_store).to receive(:publish)

        repository.store(order, stream_name)
        expect(event_store).to have_received(:publish).with([order_created], stream_name: stream_name, expected_version: -1)

        order.apply(order_expired)
        repository.store(order, stream_name)
        expect(event_store).to have_received(:publish).with([order_expired], stream_name: stream_name, expected_version: 0)
      end
    end

    describe "#with_aggregate" do
      specify do
        order_expired = Orders::Events::OrderExpired.new
        repository.with_aggregate(order_klass.new(uuid), stream_name) { |order| order.apply(order_expired) }

        expect(event_store.read.stream(stream_name).last).to eq(order_expired)
      end
    end
  end
end
