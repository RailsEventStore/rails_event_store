# frozen_string_literal: true

module RubyEventStore
  module RSpec
    class HaveSubscribedToEvents
      def initialize(mandatory_expected, *optional_expected, differ:, phraser:)
        @expected = [mandatory_expected, *optional_expected]
        @matcher = ::RSpec::Matchers::BuiltIn::ContainExactly.new(expected)
        @differ = differ
        @phraser = phraser
      end

      def matches?(handler)
        @handler = handler
        @subscribed_to = expected.select do |event|
          event_store.subscribers_for(event).include?(handler)
        end

        matcher.matches?(subscribed_to)
      end

      def in(event_store)
        @event_store = event_store
        self
      end

      def failure_message
        "expected #{handler} to be subscribed to events, diff:" +
          differ.diff(expected.to_s + "\n", subscribed_to)
      end

      def failure_message_when_negated
        "expected #{handler} not to be subscribed to events, diff:" +
          differ.diff(expected.to_s + "\n", subscribed_to)
      end

      def description
        "have subscribed to events that have to (#{phraser.(expected)})"
      end

      private

      attr_reader :expected, :handler, :subscribed_to,
                  :differ, :phraser, :matcher, :event_store
    end
  end
end

