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
    subscriber = subscriber.new if Class === subscriber
    @dispatched_events << {to: subscriber.class, event: event}
  end

  def verify(subscriber)
    subscriber = subscriber.new if Class === subscriber
    subscriber.respond_to?(:call) or raise InvalidHandler.new(subscriber)
  rescue ArgumentError
    raise InvalidHandler.new(subscriber)
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
      expect { client.subscribe(subscriber, [OrderCreated]) }.to raise_error(InvalidHandler)
    end

    specify 'throws exception if subscriber has not call method - handling all events' do
      subscriber = Subscribers::InvalidHandler.new
      expect { client.subscribe_to_all_events(subscriber) }.to raise_error(InvalidHandler)
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
      expect do
        client.subscribe(Subscribers::InvalidHandler, [OrderCreated])
      end.to raise_error(InvalidHandler)
    end

    specify 'throws exception if subscriber klass have not call method - handling all events' do
      expect do
        client.subscribe_to_all_events(Subscribers::InvalidHandler)
      end.to raise_error(InvalidHandler)
    end

    specify 'dispatch events to subscribers via proxy' do
      dispatcher = CustomDispatcher.new
      broker = PubSub::Broker.new(dispatcher: dispatcher)
      client = RubyEventStore::Client.new(repository: repository, event_broker: broker)
      client.subscribe(Subscribers::ValidHandler, [OrderCreated])
      event = OrderCreated.new
      client.publish_event(event)
      expect(dispatcher.dispatched_events).to eq [{to: Subscribers::ValidHandler, event: event}]
    end

    specify 'dispatch all events to subscribers via proxy' do
      dispatcher = CustomDispatcher.new
      broker = PubSub::Broker.new(dispatcher: dispatcher)
      client = RubyEventStore::Client.new(repository: repository, event_broker: broker)
      client.subscribe_to_all_events(Subscribers::ValidHandler)
      event = OrderCreated.new
      client.publish_event(event)
      expect(dispatcher.dispatched_events).to eq [{to: Subscribers::ValidHandler, event: event}]
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
      expect(dispatcher.dispatched_events).to eq [{to: Subscribers::ValidHandler, event: event_1}]
      expect(result).to respond_to(:call)
      expect(client.read_all_streams_forward).to eq([event_1, event_2])
    end

    specify 'dynamic subscription' do
      event_1 = OrderCreated.new
      event_2 = ProductAdded.new
      event_3 = ProductAdded.new
      types = [OrderCreated, ProductAdded]
      result = client.subscribe(h = Subscribers::ValidHandler.new, types) do
        client.publish_event(event_1)
        client.publish_event(event_2)
      end
      client.publish_event(event_3)
      expect(h.handled_events).to eq([event_1, event_2])
      expect(result).to respond_to(:call)
      expect(client.read_all_streams_forward).to eq([event_1, event_2, event_3])
    end

    specify 'dynamic subscription with exception' do
      event_1 = OrderCreated.new
      event_2 = OrderCreated.new
      exception = Class.new(StandardError)
      begin
        client.subscribe(h = Subscribers::ValidHandler.new, [OrderCreated]) do
          client.publish_event(event_1)
          raise exception
        end
      rescue exception
      end
      client.publish_event(event_2)
      expect(h.handled_events).to eq([event_1])
      expect(client.read_all_streams_forward).to eq([event_1, event_2])
    end

    specify 'notifies subscriber in the order events were published' do
      handled_events = []
      subscriber = ->(event) {
        handled_events << event
      }
      client.subscribe(subscriber, [ProductAdded, OrderCreated])
      event_1 = OrderCreated.new
      event_2 = ProductAdded.new
      client.publish_events([event_1, event_2])
      expect(handled_events).to eq [event_1, event_2]
    end

    specify 'with many subscribers they are called in the order events were published' do
      handled_events = []
      subscriber1 = ->(event) {
        handled_events << event
        handled_events << :subscriber1
      }
      client.subscribe(subscriber1, [ProductAdded, OrderCreated])
      subscriber2 = ->(event) {
        handled_events << event
        handled_events << :subscriber2
      }
      client.subscribe(subscriber2, [ProductAdded, OrderCreated])
      event_1 = OrderCreated.new
      event_2 = ProductAdded.new
      client.publish_events([event_1, event_2])
      expect(handled_events).to eq [
        event_1, :subscriber1, event_1, :subscriber2,
        event_2, :subscriber1, event_2, :subscriber2,
      ]
    end

    context "dynamic subscribe v2" do
      specify 'dynamic global subscription via proxy' do
        event_1 = OrderCreated.new
        event_2 = ProductAdded.new
        dispatcher = CustomDispatcher.new
        broker = PubSub::Broker.new(dispatcher: dispatcher)
        client = RubyEventStore::Client.new(repository: repository, event_broker: broker)

        result = client.within do
          client.publish_event(event_1)
          :yo
        end.subscribe_to_all_events(Subscribers::ValidHandler).call

        client.publish_event(event_2)

        expect(dispatcher.dispatched_events).to eq [{to: Subscribers::ValidHandler, event: event_1}]
        expect(client.read_all_streams_forward).to eq([event_1, event_2])
        expect(result).to eq(:yo)
      end

      specify 'dynamic subscription' do
        event_1 = OrderCreated.new
        event_2 = ProductAdded.new
        event_3 = ProductAdded.new
        types = [OrderCreated, ProductAdded]
        result = client.within do
          client.publish_event(event_1)
          client.publish_event(event_2)
          :result
        end.subscribe(h = Subscribers::ValidHandler.new, to: types).call

        client.publish_event(event_3)
        expect(h.handled_events).to eq([event_1, event_2])
        expect(result).to eq(:result)
        expect(client.read_all_streams_forward).to eq([event_1, event_2, event_3])
      end

      specify 'dynamic subscription with exception' do
        event_1 = OrderCreated.new
        event_2 = OrderCreated.new
        exception = Class.new(StandardError)
        begin
          client.within do
            client.publish_event(event_1)
            raise exception
          end.subscribe(h = Subscribers::ValidHandler.new, to: OrderCreated).call
        rescue exception
        end
        client.publish_event(event_2)
        expect(h.handled_events).to eq([event_1])
        expect(client.read_all_streams_forward).to eq([event_1, event_2])
      end

      specify 'chained subscriptions' do
        event_1 = OrderCreated.new
        event_2 = ProductAdded.new
        event_3 = ProductAdded.new
        h1,h2,h3,h4 = 4.times.map{Subscribers::ValidHandler.new}
        result = client.within do
          client.publish_event(event_1)
          client.publish_event(event_2)
          :result
        end.
        subscribe(h1, to: OrderCreated).
        subscribe_to_all_events(h2).
        subscribe(to: [ProductAdded]) do |ev|
          h3.call(ev)
        end.
        subscribe_to_all_events do |ev|
          h4.call(ev)
        end.
        call

        client.publish_event(event_3)
        expect(h1.handled_events).to eq([event_1])
        expect(h3.handled_events).to eq([event_2])
        expect(h2.handled_events).to eq([event_1, event_2])
        expect(h4.handled_events).to eq([event_1, event_2])
        expect(result).to eq(:result)
        expect(client.read_all_streams_forward).to eq([event_1, event_2, event_3])
      end

    end
  end
end
