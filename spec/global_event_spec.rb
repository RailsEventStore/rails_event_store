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
