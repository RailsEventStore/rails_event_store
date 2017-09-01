require "spec_helper"
require "rails_event_store"

module RailsEventStore
  module RSpec
     FooEvent = Class.new(RailsEventStore::Event)
     BarEvent = Class.new(RailsEventStore::Event)

    ::RSpec.describe EventMatcher do
      def matcher(expected)
        EventMatcher.new(expected)
      end

      specify do
        expect(FooEvent.new).to matcher(FooEvent)
      end

      specify do
        expect(FooEvent.new).not_to matcher(BarEvent)
      end
    end
  end
end
