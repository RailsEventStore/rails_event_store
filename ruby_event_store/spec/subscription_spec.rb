require 'spec_helper'

module Subscribers
  class InvalidHandler
  end

  class ValidHandler
    def initialize
      @handled_events = []
    end
    attr_reader :handled_events

    def call(event)
      @handled_events << event
    end
  end
end

class CustomDispatcher
  attr_reader :dispatched_events

  def initialize
    @dispatched_events = []
  end

  def call(subscriber, event)
    @dispatched_events << {to: subscriber.class, event: event}
  end

  def proxy_for(klass)
    ->(e) { klass.new.call(e) }
  end
end

module RubyEventStore
  RSpec.describe Client do

    let(:repository) { InMemoryRepository.new }
    let(:client)     { RubyEventStore::Client.new(repository: repository) }

    specify 'throws exception if subscriber is not defined' do
      expect { client.subscribe(nil, [])}.to raise_error(SubscriberNotExist)
      expect { client.subscribe_to_all_events(nil)}.to raise_error(SubscriberNotExist)
    end

    specify 'throws exception if subscriber has not call method - handling subscribed events' do
      subscriber = Subscribers::InvalidHandler.new
      message = "#call method not found " +
        "in Subscribers::InvalidHandler subscriber." +
        " Are you sure it is a valid subscriber?"

      expect { client.subscribe(subscriber, [OrderCreated]) }.to raise_error(InvalidHandler, message)
    end

    specify 'throws exception if subscriber has not call method - handling all events' do
      subscriber = Subscribers::InvalidHandler.new
      message = "#call method not found " +
        "in Subscribers::InvalidHandler subscriber." +
        " Are you sure it is a valid subscriber?"

      expect { client.subscribe_to_all_events(subscriber) }.to raise_error(InvalidHandler, message)
    end

    specify 'notifies subscribers listening on all events' do
      subscriber = Subscribers::ValidHandler.new
      client.subscribe_to_all_events(subscriber)
      event = OrderCreated.new
      client.publish_event(event)
      expect(subscriber.handled_events).to eq [event]
    end

    specify 'notifies subscribers listening on list of events' do
      subscriber = Subscribers::ValidHandler.new
      client.subscribe(subscriber, [OrderCreated, ProductAdded])
      event_1 = OrderCreated.new
      event_2 = ProductAdded.new
      client.publish_event(event_1)
      client.publish_event(event_2)
      expect(subscriber.handled_events).to eq [event_1, event_2]
    end

    specify 'notifies subscribers listening on all events - with lambda' do
      handled_events = []
      subscriber = ->(event) {
        handled_events << event
      }
      client.subscribe_to_all_events(subscriber)
      event = OrderCreated.new
      client.publish_event(event)
      expect(handled_events).to eq [event]
    end

    specify 'notifies subscribers listening on list of events - with lambda' do
      handled_events = []
      subscriber = ->(event) {
        handled_events << event
      }
      client.subscribe(subscriber, [OrderCreated, ProductAdded])
      event_1 = OrderCreated.new
      event_2 = ProductAdded.new
      client.publish_event(event_1)
      client.publish_event(event_2)
      expect(handled_events).to eq [event_1, event_2]
    end

    specify 'allows to provide a custom dispatcher' do
      dispatcher = CustomDispatcher.new
      broker = PubSub::Broker.new(dispatcher: dispatcher)
      client = RubyEventStore::Client.new(repository: repository, event_broker: broker)
      subscriber = Subscribers::ValidHandler.new
      client.subscribe(subscriber, [OrderCreated])
      event = OrderCreated.new
      client.publish_event(event)
      expect(dispatcher.dispatched_events).to eq [{to: Subscribers::ValidHandler, event: event}]
    end

    specify 'lambda is an output of global subscribe methods' do
      subscriber = Subscribers::ValidHandler.new
      result = client.subscribe_to_all_events(subscriber)
      expect(result).to respond_to(:call)
    end

    specify 'lambda is an output of subscribe methods' do
      subscriber = Subscribers::ValidHandler.new
      result = client.subscribe(subscriber, [OrderCreated,ProductAdded])
      expect(result).to respond_to(:call)
    end

    specify 'dynamic global subscription' do
      event_1 = OrderCreated.new
      event_2 = ProductAdded.new
      subscriber = Subscribers::ValidHandler.new
      result = client.subscribe_to_all_events(subscriber) do
        client.publish_event(event_1)
      end
      client.publish_event(event_2)
      expect(subscriber.handled_events).to eq [event_1]
      expect(result).to respond_to(:call)
      expect(client.read_all_streams_forward).to eq([event_1, event_2])
    end

    specify 'dynamic subscription' do
      event_1 = OrderCreated.new
      event_2 = ProductAdded.new
      subscriber = Subscribers::ValidHandler.new
      result = client.subscribe(subscriber, [OrderCreated, ProductAdded]) do
        client.publish_event(event_1)
      end
      client.publish_event(event_2)
      expect(subscriber.handled_events).to eq [event_1]
      expect(result).to respond_to(:call)
      expect(client.read_all_streams_forward).to eq([event_1, event_2])
    end

    specify 'subscribers receive event with enriched metadata' do
      client = RubyEventStore::Client.new(repository: repository, clock: ->{ Time.at(0) })
      received_event = nil
      client.subscribe(->(event) { received_event = event }, [OrderCreated])
      client.publish_event(OrderCreated.new)

      expect(received_event).to_not be_nil
      expect(received_event.metadata[:timestamp]).to eq(Time.at(0))
    end

    specify 'throws exception if subscriber klass does not have call method - handling subscribed events' do
      message = "#call method not found " +
        "in Subscribers::InvalidHandler subscriber." +
        " Are you sure it is a valid subscriber?"

      expect { client.subscribe(Subscribers::InvalidHandler, [OrderCreated]) }.to raise_error(InvalidHandler, message)
    end

    specify 'throws exception if subscriber klass have not call method - handling all events' do
      message = "#call method not found " +
        "in Subscribers::InvalidHandler subscriber." +
        " Are you sure it is a valid subscriber?"

      expect { client.subscribe_to_all_events(Subscribers::InvalidHandler) }.to raise_error(InvalidHandler, message)
    end

    specify 'dispatch events to subscribers via proxy' do
      dispatcher = CustomDispatcher.new
      broker = PubSub::Broker.new(dispatcher: dispatcher)
      client = RubyEventStore::Client.new(repository: repository, event_broker: broker)
      client.subscribe(Subscribers::ValidHandler, [OrderCreated])
      event = OrderCreated.new
      client.publish_event(event)
      expect(dispatcher.dispatched_events).to eq [{to: Proc, event: event}]
    end

    specify 'dispatch all events to subscribers via proxy' do
      dispatcher = CustomDispatcher.new
      broker = PubSub::Broker.new(dispatcher: dispatcher)
      client = RubyEventStore::Client.new(repository: repository, event_broker: broker)
      client.subscribe_to_all_events(Subscribers::ValidHandler)
      event = OrderCreated.new
      client.publish_event(event)
      expect(dispatcher.dispatched_events).to eq [{to: Proc, event: event}]
    end

    specify 'lambda is an output of global subscribe via proxy' do
      dispatcher = CustomDispatcher.new
      broker = PubSub::Broker.new(dispatcher: dispatcher)
      client = RubyEventStore::Client.new(repository: repository, event_broker: broker)
      result = client.subscribe_to_all_events(Subscribers::ValidHandler)
      expect(result).to respond_to(:call)
    end

    specify 'lambda is an output of subscribe via proxy' do
      dispatcher = CustomDispatcher.new
      broker = PubSub::Broker.new(dispatcher: dispatcher)
      client = RubyEventStore::Client.new(repository: repository, event_broker: broker)
      result = client.subscribe(Subscribers::ValidHandler, [OrderCreated])
      expect(result).to respond_to(:call)
    end

    specify 'dynamic global subscription via proxy' do
      event_1 = OrderCreated.new
      event_2 = ProductAdded.new
      dispatcher = CustomDispatcher.new
      broker = PubSub::Broker.new(dispatcher: dispatcher)
      client = RubyEventStore::Client.new(repository: repository, event_broker: broker)
      result = client.subscribe_to_all_events(Subscribers::ValidHandler) do
        client.publish_event(event_1)
      end
      client.publish_event(event_2)
      expect(dispatcher.dispatched_events).to eq [{to: Proc, event: event_1}]
      expect(result).to respond_to(:call)
      expect(client.read_all_streams_forward).to eq([event_1, event_2])
    end

    specify 'dynamic subscription' do
      event_1 = OrderCreated.new
      event_2 = ProductAdded.new
      dispatcher = CustomDispatcher.new
      broker = PubSub::Broker.new(dispatcher: dispatcher)
      client = RubyEventStore::Client.new(repository: repository, event_broker: broker)
      result = client.subscribe(Subscribers::ValidHandler, [OrderCreated, ProductAdded]) do
        client.publish_event(event_1)
      end
      client.publish_event(event_2)
      expect(dispatcher.dispatched_events).to eq [{to: Proc, event: event_1}]
      expect(result).to respond_to(:call)
      expect(client.read_all_streams_forward).to eq([event_1, event_2])
    end
  end
end
