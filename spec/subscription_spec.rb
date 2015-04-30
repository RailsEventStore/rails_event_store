require 'spec_helper'

module Subscribers
  class IncorrectDenormalizer
  end

  class OrderDenormalizer
    def initialize
      @handled_events = 0
    end
    attr_reader :handled_events

    def handle_event(event)
      @handled_events += 1 if event.event_type == 'OrderCreated' || event.event_type == 'ProductAdded'
    end
  end
end

module RailsEventStore
  describe Client do

    let(:repository) { EventInMemoryRepository.new }
    let(:client)     { RailsEventStore::Client.new(repository) }

    specify 'throws exception if subscriber is not defined' do
      expect { client.subscribe(nil, [])}.to raise_error(SubscriberNotExist)
      expect { client.subscribe_to_all_events(nil)}.to raise_error(SubscriberNotExist)
    end

    specify 'throws exception if subscriber has not handle_event method' do
      subscriber = Subscribers::IncorrectDenormalizer.new
      expect { client.subscribe(subscriber, [])}.to raise_error(MethodNotDefined)
      expect { client.subscribe_to_all_events(subscriber)}.to raise_error(MethodNotDefined)
    end

    specify 'notifies subscribers listening on all events' do
      subscriber = Subscribers::OrderDenormalizer.new
      client.subscribe_to_all_events(subscriber)
      event = OrderCreated.new
      client.publish_event(event)
      expect(subscriber.handled_events).to eq 1
    end

    specify 'notifies subscribers listening on list of events' do
      subscriber = Subscribers::OrderDenormalizer.new
      client.subscribe(subscriber, ['OrderCreated', 'ProductAdded'])
      event_1 = OrderCreated.new
      event_2 = ProductAdded.new
      client.publish_event(event_1)
      client.publish_event(event_2)
      expect(subscriber.handled_events).to eq 2
    end

  end
end
