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
      @handled_events += 1 if event.is_a?(OrderCreated) || event.is_a?(ProductAdded)
    end
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

    specify 'throws exception if subscriber has not handle_event method' do
      subscriber = Subscribers::IncorrectDenormalizer.new
      expect { facade.subscribe(subscriber, [])}.to raise_error(MethodNotDefined)
      expect { facade.subscribe_to_all_events(subscriber)}.to raise_error(MethodNotDefined)
    end

    specify 'notifies subscribers listening on all events' do
      subscriber = Subscribers::OrderDenormalizer.new
      facade.subscribe_to_all_events(subscriber)
      event = OrderCreated.new
      facade.publish_event(event)
      expect(subscriber.handled_events).to eq 1
    end

    specify 'notifies subscribers listening on list of events' do
      subscriber = Subscribers::OrderDenormalizer.new
      facade.subscribe(subscriber, [OrderCreated, ProductAdded])
      event_1 = OrderCreated.new
      event_2 = ProductAdded.new
      facade.publish_event(event_1)
      facade.publish_event(event_2)
      expect(subscriber.handled_events).to eq 2
    end

  end
end
