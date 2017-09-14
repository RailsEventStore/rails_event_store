module RailsEventStore
  module RSpec
    module Matchers
      def be_an_event(expected)
        BeEvent.new(expected, differ: differ)
      end
      alias :be_event :be_an_event
      alias :an_event :be_an_event
      alias :event    :be_an_event

      def have_published(*expected)
        HavePublished.new(*expected)
      end

      def have_applied(*expected)
        HaveApplied.new(*expected, differ: differ)
      end

      private

      def differ
        ::RSpec::Support::Differ.new(color: ::RSpec::Matchers.configuration.color?)
      end
    end
  end
end
