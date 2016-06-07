require 'spec_helper'

module Subscribers
  class IncorrectDenormalizer
  end

  class HandlerWithHandleEventMethod
    def initialize
      @handled_events = 0
    end
    attr_reader :handled_events

    def handle_event(event)
      @handled_events += 1 if event.is_a?(OrderCreated) || event.is_a?(ProductAdded)
    end
  end

  class HandlerWithCallMethod
    def initialize
      @handled_events = 0
    end
    attr_reader :handled_events

    def call(event)
      @handled_events += 1 if event.is_a?(OrderCreated) || event.is_a?(ProductAdded)
    end
  end
end

class CustomDispatcher
  attr_reader :dispatched_events

  def initialize
    @dispatched_events = 0
  end

  def call(subscriber, event)
    @dispatched_events += 1
  end
end

module RubyEventStore
  describe Facade do

    let(:repository) { InMemoryRepository.new }
    let(:facade)     { RubyEventStore::Facade.new(repository) }

    specify 'throws exception if subscriber is not defined' do
      expect { facade.subscribe(nil, [])}.to raise_error(SubscriberNotExist)
      expect { facade.subscribe_to_all_events(nil)}.to raise_error(SubscriberNotExist)
    end

    specify 'throws exception if subscriber has not call & handle_event method - handling subscribed events' do
      subscriber = Subscribers::IncorrectDenormalizer.new
      message = "Neither #call nor #handle_event method found " +
                "in Subscribers::IncorrectDenormalizer subscriber." +
                " Are you sure it is a valid subscriber?"

      facade.subscribe(subscriber, [OrderCreated])
      expect { facade.publish_event(OrderCreated.new) }.to raise_error(MethodNotDefined,
                                                                       message)
    end

    specify 'throws exception if subscriber has not call & handle_event method - handling all events' do
      subscriber = Subscribers::IncorrectDenormalizer.new
      message = "Neither #call nor #handle_event method found " +
                "in Subscribers::IncorrectDenormalizer subscriber." +
                " Are you sure it is a valid subscriber?"

      facade.subscribe_to_all_events(subscriber)
      expect { facade.publish_event(ProductAdded.new) }.to raise_error(MethodNotDefined,
                                                                       message)
    end

    specify 'notifies subscribers listening on all events - with call' do
      subscriber = Subscribers::HandlerWithCallMethod.new
      facade.subscribe_to_all_events(subscriber)
      event = OrderCreated.new
      facade.publish_event(event)
      expect(subscriber.handled_events).to eq 1
    end

    specify 'notifies subscribers listening on list of events - with call' do
      subscriber = Subscribers::HandlerWithCallMethod.new
      facade.subscribe(subscriber, [OrderCreated, ProductAdded])
      event_1 = OrderCreated.new
      event_2 = ProductAdded.new
      facade.publish_event(event_1)
      facade.publish_event(event_2)
      expect(subscriber.handled_events).to eq 2
    end

    specify 'notifies subscribers listening on all events - with handle_event' do
      subscriber = Subscribers::HandlerWithHandleEventMethod.new
      facade.subscribe_to_all_events(subscriber)
      event = OrderCreated.new
      facade.publish_event(event)
      expect(subscriber.handled_events).to eq 1
    end

    specify 'notifies subscribers listening on list of events - with handle_event' do
      subscriber = Subscribers::HandlerWithHandleEventMethod.new
      facade.subscribe(subscriber, [OrderCreated, ProductAdded])
      event_1 = OrderCreated.new
      event_2 = ProductAdded.new
      facade.publish_event(event_1)
      facade.publish_event(event_2)
      expect(subscriber.handled_events).to eq 2
    end

    specify 'notifies subscribers listening on all events - with lambda' do
      handled_events = 0
      subscriber = ->(event) {
        handled_events += 1 if event.is_a?(OrderCreated) || event.is_a?(ProductAdded)
      }
      facade.subscribe_to_all_events(subscriber)
      event = OrderCreated.new
      facade.publish_event(event)
      expect(handled_events).to eq 1
    end

    specify 'notifies subscribers listening on list of events - with lambda' do
      handled_events = 0
      subscriber = ->(event) {
        handled_events += 1 if event.is_a?(OrderCreated) || event.is_a?(ProductAdded)
      }
      facade.subscribe(subscriber, [OrderCreated, ProductAdded])
      event_1 = OrderCreated.new
      event_2 = ProductAdded.new
      facade.publish_event(event_1)
      facade.publish_event(event_2)
      expect(handled_events).to eq 2
    end

    specify 'allows to provide a custom dispatcher' do
      dispatcher = CustomDispatcher.new
      broker = PubSub::Broker.new(dispatcher)
      facade = RubyEventStore::Facade.new(repository, broker)
      facade.subscribe(Subscribers::HandlerWithHandleEventMethod.new, [OrderCreated])
      facade.publish_event(OrderCreated.new)
      expect(dispatcher.dispatched_events).to eq(1)
    end

    specify 'lambda is an output of global subscribe methods' do
      subscriber = Subscribers::OrderDenormalizer.new
      result = facade.subscribe_to_all_events(subscriber)
      expect(result).to respond_to(:call)
    end

    specify 'lambda is an output of subscribe methods' do
      subscriber = Subscribers::OrderDenormalizer.new
      result = facade.subscribe(subscriber, [OrderCreated,ProductAdded])
      expect(result).to respond_to(:call)
    end

    specify 'dynamic global subscription' do
      event_1 = OrderCreated.new
      event_2 = ProductAdded.new
      subscriber = Subscribers::OrderDenormalizer.new
      result = facade.subscribe_to_all_events(subscriber) do
        facade.publish_event(event_1)
      end
      facade.publish_event(event_2)
      expect(subscriber.handled_events).to eq(1)
      expect(result).to respond_to(:call)
      expect(facade.read_all_streams_forward(:head, 10)).to eq([event_1, event_2])
    end

    specify 'dynamic subscription' do
      event_1 = OrderCreated.new
      event_2 = ProductAdded.new
      subscriber = Subscribers::OrderDenormalizer.new
      result = facade.subscribe(subscriber, [OrderCreated, ProductAdded]) do
        facade.publish_event(event_1)
      end
      facade.publish_event(event_2)
      expect(subscriber.handled_events).to eq(1)
      expect(result).to respond_to(:call)
      expect(facade.read_all_streams_forward(:head, 10)).to eq([event_1, event_2])
    end

    specify 'deprecation message when no call method in handler' do
      subscriber = Subscribers::HandlerWithHandleEventMethod.new
      facade.subscribe_to_all_events(subscriber)
      expect { facade.publish_event(OrderCreated.new) }.to output(
        "[DEPRECATION] `handle_event` is deprecated.  Please use `call` instead.\n").to_stderr
    end
  end
end
