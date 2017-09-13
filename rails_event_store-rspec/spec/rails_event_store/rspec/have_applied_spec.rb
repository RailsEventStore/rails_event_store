require "spec_helper"

module RailsEventStore
  module RSpec
    ::RSpec.describe HaveApplied do
      let(:matchers) { Object.new.tap { |o| o.extend(Matchers) } }
      let(:aggregate_root) { TestAggregate.new }

      def matcher(expected)
        HaveApplied.new(expected)
      end

      specify do
        aggregate_root.foo
        expect(aggregate_root).to matcher(matchers.an_event(FooEvent))
      end

      specify do
        aggregate_root.foo
        expect(aggregate_root).not_to matcher(matchers.an_event(BazEvent))
      end
    end
  end
end
