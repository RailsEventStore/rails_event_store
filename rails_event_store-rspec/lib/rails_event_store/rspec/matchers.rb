# frozen_string_literal: true

module RailsEventStore
  module RSpec
    module Matchers
      class ListPhraser
        class << self
          def call(object)
            items = Array(object).compact.map { |o| format(o) }
            return "" if items.empty?
            if items.one?
              items.join
            else
              "#{items[all_but_last].join(", ")} and #{items.fetch(-1)}"
            end
          end

          private

          def all_but_last
            (0...-1)
          end

          def format(object)
            if object.respond_to?(:description)
              ::RSpec::Support::ObjectFormatter.format(object)
            else
              "be a #{object}"
            end
          end
        end
      end

      def be_an_event(expected)
        BeEvent.new(expected, differ: differ, formatter: formatter)
      end
      alias :be_event :be_an_event
      alias :an_event :be_an_event
      alias :event    :be_an_event

      def have_published(*expected)
        HavePublished.new(*expected, differ: differ, phraser: phraser)
      end

      def have_applied(*expected)
        HaveApplied.new(*expected, differ: differ, phraser: phraser)
      end

      def publish(*expected)
        Publish.new(*expected)
      end

      def apply(*expected)
        Apply.new(*expected)
      end

      private

      def formatter
        ::RSpec::Support::ObjectFormatter.public_method(:format)
      end

      def differ
        ::RSpec::Support::Differ.new(color: ::RSpec::Matchers.configuration.color?)
      end

      def phraser
        ListPhraser
      end
    end
  end
end
