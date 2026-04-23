# frozen_string_literal: true

require "spec_helper"

module RubyEventStore
  module Browser
    module EventTypesQuerying
      ::RSpec.describe EventType do
        specify "can be initialized with event_type and stream_name" do
          event_type = EventType.new(event_type: "OrderPlaced", stream_name: "$by_type_OrderPlaced")

          expect(event_type.event_type).to eq("OrderPlaced")
          expect(event_type.stream_name).to eq("$by_type_OrderPlaced")
        end

        specify "requires event_type keyword argument" do
          expect { EventType.new(stream_name: "$by_type_OrderPlaced") }.to raise_error(ArgumentError)
        end

        specify "requires stream_name keyword argument" do
          expect { EventType.new(event_type: "OrderPlaced") }.to raise_error(ArgumentError)
        end
      end
    end
  end
end
