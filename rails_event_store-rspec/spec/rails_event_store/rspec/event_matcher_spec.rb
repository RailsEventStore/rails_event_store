require "spec_helper"
require "rails_event_store"

module RailsEventStore
  module RSpec
    ::FooEvent = Class.new(RailsEventStore::Event)
    ::BarEvent = Class.new(RailsEventStore::Event)

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
      specify do
        _matcher = matcher(FooEvent)
        _matcher.matches?(BarEvent.new)

        expect(_matcher.failure_message).to eq(%q{
expected: FooEvent
     got: BarEvent
})
      end

      specify do
        _matcher = matcher(FooEvent)
        _matcher.matches?(FooEvent.new)

        expect(_matcher.failure_message_when_negated).to eq(%q{
expected: not a kind of FooEvent
     got: FooEvent
})
      end

      specify do
        expect(FooEvent.new(data: { baz: "bar" })).to matcher(FooEvent).with_data({ baz: "bar" })
      end

      specify do
        expect(FooEvent.new(data: { baz: "bar" })).not_to matcher(FooEvent).with_data({ baz: "foo" })
      end

      specify do
        expect(FooEvent.new(data: { baz: "bar" })).not_to matcher(FooEvent).with_data({ foo: "bar" })
      end
    end
  end
end
