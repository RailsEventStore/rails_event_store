require "spec_helper"

module RailsEventStore
  module RSpec
    ::RSpec.describe HavePublished do
      let(:matchers) { Object.new.tap { |o| o.extend(Matchers) } }
      let(:event_store) do
        RailsEventStore::Client.new(repository: RailsEventStore::InMemoryRepository.new)
      end

      def matcher(expected)
        HavePublished.new(expected)
      end

      specify do
        event_store.publish_event(FooEvent.new)
        expect(event_store).to matcher(matchers.an_event(FooEvent))
      end

      specify do
        event_store.publish_event(BarEvent.new)
        expect(event_store).not_to matcher(matchers.an_event(FooEvent))
      end
    end
  end
end
