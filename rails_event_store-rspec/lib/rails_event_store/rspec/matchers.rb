module RailsEventStore
  module RSpec
    module Matchers
      class ListPhraser
        def self.call(object)
          items = Array(object).compact.map { |o| format(o) }
          return "" if items.empty?
          if items.one?
            items.join
          else
            "#{items[0...-1].join(", ")}#{" and "}#{items.fetch(-1)}"
          end
        end

        private

        def self.format(object)
          if object.respond_to?(:description)
            ::RSpec::Support::ObjectFormatter.format(object)
          else
            "be a #{object}"
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

      def publish(event = nil, &block)
        Publish.new(event, &block)
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
