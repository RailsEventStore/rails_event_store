# frozen_string_literal: true

module RubyEventStore
  module RSpec
    module Matchers
      class ListPhraser
        class << self
          def call(object)
            items = Array(object).compact.map { |o| format(o) }
            return "" if items.empty?
            items.one? ? items.join : "#{items[all_but_last].join(", ")} and #{items.fetch(-1)}"
          end

          private

          def all_but_last
            (0...-1)
          end

          def format(object)
            object.respond_to?(:description) ? ::RSpec::Support::ObjectFormatter.format(object) : "be a #{object}"
          end
        end
      end

      def be_an_event(expected)
        BeEvent.new(expected, differ: differ, formatter: formatter)
      end
      alias be_event be_an_event
      alias an_event be_an_event
      alias event be_an_event

      def have_published(*expected)
        HavePublished.new(
          *expected,
          phraser: phraser,
          failure_message_formatter: RSpec.default_formatter.have_published(differ),
        )
      end

      def have_applied(*expected)
        HaveApplied.new(
          *expected,
          phraser: phraser,
          failure_message_formatter: RSpec.default_formatter.have_applied(differ),
        )
      end

      def have_subscribed_to_events(*expected)
        HaveSubscribedToEvents.new(*expected, differ: differ, phraser: phraser)
      end

      def publish(*expected)
        Publish.new(*expected, failure_message_formatter: RSpec.default_formatter.publish(differ))
      end

      def apply(*expected)
        Apply.new(*expected, failure_message_formatter: RSpec.default_formatter.apply(differ))
      end

      private

      def formatter
        ::RSpec::Support::ObjectFormatter.public_method(:format)
      end

      def differ
        ::RSpec::Expectations.differ
      end

      def phraser
        ListPhraser
      end
    end
  end
end
