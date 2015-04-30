require 'spec_helper'

module RailsEventStore::EventHandlers
  describe EventHandler do
    specify "should have handle_event method" do
      event_handler = EventHandler.new
      expect(event_handler).to respond_to(:handle_event)
    end

    specify "#handle_event should accept one argument" do
      event_handler = EventHandler.new
      event_handler.handle_event("foo")
    end
  end
end
