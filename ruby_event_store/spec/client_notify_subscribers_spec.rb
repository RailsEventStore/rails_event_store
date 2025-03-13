# frozen_string_literal: true

require "spec_helper"
require "time"

module RubyEventStore
  ::RSpec.describe Client do
    Test1DomainEvent = Class.new(Event)
    Test2DomainEvent = Class.new(Event)
    Test3DomainEvent = Class.new(Event)

    class InvalidTestHandler
    end

    class TestHandler
      def initialize
        @events = []
      end

      def call(event)
        @events << event
      end

      attr_reader :events
    end

    class TestDispatcher
      attr_reader :dispatched

      def initialize
        @dispatched = []
      end

      def verify(_subscriber)
        true
      end

      def call(subscriber, event, record)
        @dispatched << { subscriber: subscriber, event: event, record: record }
      end
    end

    subject(:client) { Client.new }

    it "notifies subscribed handlers" do
      handler = TestHandler.new
      another_handler = TestHandler.new
      global_handler = TestHandler.new

      client.subscribe(handler, to: [Test1DomainEvent, Test3DomainEvent])
      client.subscribe(another_handler, to: [Test2DomainEvent])
      client.subscribe_to_all_events(global_handler)

      event1 = Test1DomainEvent.new
      event2 = Test2DomainEvent.new
      event3 = Test3DomainEvent.new

      [event1, event2, event3].each { |ev| client.publish(ev) }

      expect(handler.events).to eq([event1, event3])
      expect(another_handler.events).to eq([event2])
      expect(global_handler.events).to eq([event1, event2, event3])
    end

    it "notifies subscribed thread handlers" do
      handler = TestHandler.new
      another_handler = TestHandler.new
      global_handler = TestHandler.new

      event1 = Test1DomainEvent.new
      event2 = Test2DomainEvent.new
      event3 = Test3DomainEvent.new

      client
        .within { [event1, event2, event3].each { |ev| client.publish(ev) } }
        .subscribe(handler, to: [Test1DomainEvent, Test3DomainEvent])
        .subscribe(another_handler, to: [Test2DomainEvent])
        .subscribe_to_all_events(global_handler)
        .call

      expect(handler.events).to eq([event1, event3])
      expect(another_handler.events).to eq([event2])
      expect(global_handler.events).to eq([event1, event2, event3])
    end

    it "raises error when no valid method on handler" do
      subscriber = InvalidTestHandler.new
      expect { client.subscribe(subscriber, to: [Test1DomainEvent]) }.to raise_error(InvalidHandler)
    end

    it "raises error when no valid method on global handler" do
      subscriber = InvalidTestHandler.new
      expect { client.subscribe_to_all_events(subscriber) }.to raise_error(InvalidHandler)
    end

    it "raises error when no valid method on thread handler" do
      subscriber = InvalidTestHandler.new
      expect { client.within {}.subscribe(subscriber, to: [Test1DomainEvent]).call }.to raise_error(
        InvalidHandler
      )
    end

    it "raises error when no valid method on global thread handler" do
      subscriber = InvalidTestHandler.new
      expect { client.within {}.subscribe(subscriber, to: [Test1DomainEvent]).call }.to raise_error(
        InvalidHandler
      )
    end

    it "returns lambda as an output of global subscribe methods" do
      handler = TestHandler.new
      result = client.subscribe_to_all_events(handler)
      expect(result).to respond_to(:call)
    end

    it "returns lambda as an output of subscribe methods" do
      handler = TestHandler.new
      result = client.subscribe(handler, to: [Test1DomainEvent, Test2DomainEvent])
      expect(result).to respond_to(:call)
    end

    it "revokes global subscription" do
      handler = TestHandler.new
      event1 = Test1DomainEvent.new
      event2 = Test2DomainEvent.new

      revoke = client.subscribe_to_all_events(handler)
      client.publish(event1)
      expect(handler.events).to eq([event1])
      revoke.()
      client.publish(event2)
      expect(handler.events).to eq([event1])
    end

    it "revokes subscription" do
      handler = TestHandler.new
      event1 = Test1DomainEvent.new
      event2 = Test2DomainEvent.new

      revoke = client.subscribe(handler, to: [Test1DomainEvent, Test2DomainEvent])
      client.publish(event1)
      expect(handler.events).to eq([event1])
      revoke.()
      client.publish(event2)
      expect(handler.events).to eq([event1])
    end

    it "revokes thread global subscription" do
      handler = TestHandler.new
      event1 = Test1DomainEvent.new
      event2 = Test2DomainEvent.new

      client.within { client.publish(event1) }.subscribe_to_all_events(handler).call
      expect(handler.events).to eq([event1])
      client.publish(event2)
      expect(handler.events).to eq([event1])
    end

    it "revokes thread subscription" do
      handler = TestHandler.new
      event1 = Test1DomainEvent.new
      event2 = Test2DomainEvent.new

      client.within { client.publish(event1) }.subscribe(handler, to: [Test1DomainEvent, Test2DomainEvent]).call
      expect(handler.events).to eq([event1])
      client.publish(event2)
      expect(handler.events).to eq([event1])
    end

    it "allows to provide a custom dispatcher" do
      dispatcher = TestDispatcher.new
      handler = TestHandler.new
      event1 = TimeEnrichment.with(Test1DomainEvent.new)

      mapper = Mappers::Default.new
      client_with_custom_dispatcher =
        Client.new(
          mapper: mapper,
          message_broker: Broker.new(dispatcher: dispatcher)
        )
      client_with_custom_dispatcher.subscribe(handler, to: [Test1DomainEvent])
      client_with_custom_dispatcher.publish(event1)
      expect(dispatcher.dispatched).to eq(
        [{ subscriber: handler, event: event1, record: mapper.event_to_record(event1) }]
      )
    end

    it "subscribes by type of event which is a String" do
      handler = TestHandler.new
      event1 = Test1DomainEvent.new

      client.subscribe(handler, to: ["RubyEventStore::Test1DomainEvent"])
      client.publish(event1)
      expect(handler.events).to eq([event1])
    end

    it "subscribes by type of event which is a String" do
      handler = TestHandler.new
      event1 = Test1DomainEvent.new

      client.within { client.publish(event1) }.subscribe(handler, to: ["RubyEventStore::Test1DomainEvent"]).call

      expect(handler.events).to eq([event1])
    end
  end
end
