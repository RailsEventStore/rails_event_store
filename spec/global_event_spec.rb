require 'spec_helper'

module RailsEventStore


  describe "Event Store" do
    specify "global event" do
      client = Client.new(EventInMemoryRepository.new)
      observer = Observer.new
      client.subscribe_to_all_events(observer)
      client.publish_event({event_type: "LessonCreated"})

      expect(observer.events.length).to(eql(1))
    end

    specify "published event has proper type" do
      client = Client.new(EventInMemoryRepository.new)
      observer = Observer.new
      client.subscribe_to_all_events(observer)
      client.publish_event({event_type: "LessonCreated"})
      expect(observer.events[0][:event_type]).to(eql("LessonCreated"))
    end

    specify "published event has the right event type" do
      client = Client.new(EventInMemoryRepository.new)
      observer = Observer.new
      client.subscribe_to_all_events(observer)
      client.publish_event({event_type: "OrderCreated"})
      expect(observer.events[0][:event_type]).to(eql("OrderCreated"))
    end

    specify "published event contains empty data when event had no data" do
      client = Client.new(EventInMemoryRepository.new)
      observer = Observer.new
      client.subscribe_to_all_events(observer)
      client.publish_event({event_type: "OrderCreated"})
      expect(observer.events[0][:data]).to_not be_nil
    end

    specify "published event contains the event data" do
      client = Client.new(EventInMemoryRepository.new)
      observer = Observer.new
      client.subscribe_to_all_events(observer)
      client.publish_event({event_type: "OrderCreated", data: {foo: 0}})
      expect(observer.events[0][:data]).to(eql({foo: 0}))
    end

    class Observer
      def initialize
        @events = []
      end
      attr_reader :events

      def handle_event(event)
        @events << event
      end
    end
  end

end
