module RailsEventStore
  module RSpec
    module Matchers
      def be_an_event(expected)
        EventMatcher.new(expected, differ: differ)
      end

      private

      def differ
        ::RSpec::Support::Differ.new(color: ::RSpec::Matchers.configuration.color?)
      end
    end
  end
end
