module RailsEventStore
  module RSpec
    module Matchers
      def be_an_event(expected)
        BeEvent.new(expected, differ: differ, formatter: formatter)
      end
      alias :be_event :be_an_event
      alias :an_event :be_an_event
      alias :event    :be_an_event

      def have_published(*expected)
        HavePublished.new(*expected, differ: differ, formatter: formatter, lister: lister)
      end

      def have_applied(*expected)
        HaveApplied.new(*expected, differ: differ, formatter: formatter, lister: lister)
      end

      private

      def formatter
        ::RSpec::Support::ObjectFormatter.method(:format)
      end

      def differ
        ::RSpec::Support::Differ.new(color: ::RSpec::Matchers.configuration.color?)
      end

      def lister
        ::RSpec::Matchers::EnglishPhrasing.method(:list)
      end
    end
  end
end
