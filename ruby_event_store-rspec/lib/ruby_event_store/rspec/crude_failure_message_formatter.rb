# frozen_string_literal: true

module RubyEventStore
  module RSpec
    module CrudeFailureMessageFormatter
      class HavePublished
        def initialize(differ)
          @differ = differ
        end

        def failure_message(expected, events, _stream_name)
          "expected #{expected.events} to be published, diff:" +
            differ.diff(expected.events.to_s + "\n", events.to_a)
        end

        def failure_message_when_negated(expected, events)
          "expected #{expected.events} not to be published, diff:" +
            differ.diff(expected.events.to_s + "\n", events.to_a)
        end

        private
        attr_reader :differ
      end

      def self.have_published
        HavePublished
      end
    end
  end
end
