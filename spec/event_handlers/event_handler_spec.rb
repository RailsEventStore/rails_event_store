require 'spec_helper'

module RailsEventStore::EventHandlers
  describe EventHandler do
    specify "should have handle_event method" do
      event_handler = EventHandler.new
      expect(event_handler).to respond_to(:handle_event)
    end
  end
end
