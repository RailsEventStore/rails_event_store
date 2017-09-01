require "spec_helper"
require "rails_event_store"

module RailsEventStore
  module RSpec
     DomainEvent = Class.new(RailsEventStore::Event)

    ::RSpec.describe EventMatcher do
      def matcher(expected)
        EventMatcher.new(expected)
      end

      specify do
        expect(DomainEvent.new).to matcher(DomainEvent)
      end
    end
  end
end
