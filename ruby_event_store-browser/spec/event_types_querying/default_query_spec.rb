# frozen_string_literal: true

require "spec_helper"

module RubyEventStore
  module Browser
    module EventTypesQuerying
      ::RSpec.describe DefaultQuery do
        before do
          # Define test event classes for shared examples
          test_event_1 = Class.new(RubyEventStore::Event)
          stub_const("SharedExampleEvent1", test_event_1)

          test_event_2 = Class.new(RubyEventStore::Event)
          stub_const("SharedExampleEvent2", test_event_2)
        end

        it_behaves_like :event_types_query, -> { DefaultQuery.new(RubyEventStore::Client.new) }.call

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

          # Stub subclasses to return empty array
          allow(RubyEventStore::Event).to receive(:subclasses).and_return([])

          query = DefaultQuery.new(event_store)
          result = query.call

          expect(result).to eq([])
        end

        specify "filters out classes without names" do
          event_store = RubyEventStore::Client.new

          # Create an anonymous event class (no name)
          anonymous_event_class = Class.new(RubyEventStore::Event)

          # Create a named event class
          named_event_class = Class.new(RubyEventStore::Event)
          stub_const("NamedEvent", named_event_class)

          query = DefaultQuery.new(event_store)
          result = query.call

          event_types = result.map(&:event_type)
          expect(event_types).to include("NamedEvent")
          expect(event_types).not_to include(nil)
        end

        specify "filters out non-Event classes" do
          event_store = RubyEventStore::Client.new

          # Define event classes
          event_class = Class.new(RubyEventStore::Event)
          stub_const("MyEvent", event_class)

          # Define non-event class
          non_event_class = Class.new
          stub_const("NonEvent", non_event_class)

          query = DefaultQuery.new(event_store)
          result = query.call

          event_types = result.map(&:event_type)
          expect(event_types).to include("MyEvent")
          expect(event_types).not_to include("NonEvent")
        end

        specify "stream name uses class name, not class object" do
          event_store = RubyEventStore::Client.new

          event_class = Class.new(RubyEventStore::Event)
          stub_const("TestEventClass", event_class)

          query = DefaultQuery.new(event_store)
          result = query.call

          test_event_type = result.find { |et| et.event_type == "TestEventClass" }
          expect(test_event_type.stream_name).to eq("$by_type_TestEventClass")
          expect(test_event_type.stream_name).not_to match(/Class:0x/)
        end

        specify "deduplicates classes with same name" do
          event_store = RubyEventStore::Client.new

          # Create event class
          event_class = Class.new(RubyEventStore::Event)
          stub_const("DuplicateEvent", event_class)

          # Create a subclass with the same name (edge case)
          # This simulates the rare case where class reloading might cause duplicates
          duplicate_class = Class.new(RubyEventStore::Event)
          allow(duplicate_class).to receive(:name).and_return("DuplicateEvent")
          allow(duplicate_class).to receive(:subclasses).and_return([])

          # Stub to return the duplicate
          allow(RubyEventStore::Event).to receive(:subclasses).and_return([event_class, duplicate_class])
          allow(event_class).to receive(:subclasses).and_return([])

          query = DefaultQuery.new(event_store)
          result = query.call

          duplicate_events = result.select { |et| et.event_type == "DuplicateEvent" }
          expect(duplicate_events.count).to eq(1)
        end
      end
    end
  end
end
