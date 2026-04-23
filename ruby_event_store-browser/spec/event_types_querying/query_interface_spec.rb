# frozen_string_literal: true

require "spec_helper"

module RubyEventStore
  module Browser
    module EventTypesQuerying
      ::RSpec.describe "Event Types Query Interface" do
        specify "defines the interface contract" do
          # This spec documents the expected interface for event types query objects.
          # Any query object implementing this interface should:
          #
          # 1. Accept an event_store argument in the initializer
          # 2. Respond to #call method
          # 3. Return an Array of EventType objects from #call
          #
          # To verify a query object conforms to this interface, use:
          #   it_behaves_like :event_types_query, YourQueryClass
        end
      end
    end
  end
end
