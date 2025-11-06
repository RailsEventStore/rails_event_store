# frozen_string_literal: true

require "spec_helper"

module RubyEventStore
  module Browser
    module EventTypesQuerying
      ::RSpec.describe DefaultQuery do
        it_behaves_like :event_types_query, DefaultQuery

        specify "finds all classes inheriting from RubyEventStore::Event" do
          event_store = RubyEventStore::Client.new

          # Define some test event classes
          test_event_1 = Class.new(RubyEventStore::Event)
          stub_const("TestEvent1", test_event_1)

          test_event_2 = Class.new(RubyEventStore::Event)
          stub_const("TestEvent2", test_event_2)

          query = DefaultQuery.new(event_store)
          result = query.call

          event_types = result.map(&:event_type)
          expect(event_types).to include("TestEvent1", "TestEvent2")
        end

        specify "generates stream names in format $by_type_EVENT_NAME" do
          event_store = RubyEventStore::Client.new

          test_event = Class.new(RubyEventStore::Event)
          stub_const("OrderPlaced", test_event)

          query = DefaultQuery.new(event_store)
          result = query.call

          order_placed_type = result.find { |et| et.event_type == "OrderPlaced" }
          expect(order_placed_type.stream_name).to eq("$by_type_OrderPlaced")
        end

        specify "returns empty array when no event classes are defined" do
          event_store = RubyEventStore::Client.new

          # Remove all test event classes from ObjectSpace
          allow(ObjectSpace).to receive(:each_object).with(Class).and_return([])

          query = DefaultQuery.new(event_store)
          result = query.call

          expect(result).to eq([])
        end
      end
    end
  end
end
