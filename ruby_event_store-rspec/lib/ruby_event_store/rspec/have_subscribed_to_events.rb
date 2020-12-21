# frozen_string_literal: true

module RubyEventStore
  module RSpec
    class HaveSubscribedToEvents
      def initialize(*events, differ:, phraser:)
        @events  = events
        @matcher = ::RSpec::Matchers::BuiltIn::ContainExactly.new(events)
        @differ = differ
        @phraser = phraser
      end

      def matches?(handler)
        @handler = handler
        @subscribed_to = events.select do |event|
          event_store.event_subscribers(event).include?(handler)
        end

        matcher.matches?(subscribed_to)
      end

      def does_not_match?(handler)
        @handler = handler
        @not_subscribed_to = events.select do |event|
          !event_store.event_subscribers(event).include?(handler)
        end

        matcher.matches?(not_subscribed_to)
      end


      def in(event_store)
        @event_store = event_store
        self
      end

      def failure_message
        "expected #{handler} to be subscribed to events, diff:" +
          differ.diff_as_string(events.to_s, subscribed_to.to_s)
      end

      def failure_message_when_negated
        "expected #{handler} not to be subscribed to events, diff:" +
          differ.diff_as_string(events.to_s, subscribed_to.to_s)
      end

      def description
        "have subscribed to events that have to (#{phraser.(events)})"
      end

      private

      attr_reader :events, :handler, :subscribed_to, :not_subscribed_to,
                  :differ, :phraser, :matcher, :event_store
    end
  end
end

