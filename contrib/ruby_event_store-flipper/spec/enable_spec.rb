require "spec_helper"

module RubyEventStore
  ::RSpec.describe Flipper do
    specify do
      event_store = RubyEventStore::Client.new(repository: RubyEventStore::InMemoryRepository.new)
      flipper = ::Flipper.new(::Flipper::Adapters::Memory.new, instrumenter: ActiveSupport::Notifications)

      Flipper.enable(event_store)
      flipper.add(:foo_bar)

      expect(event_store).to have_published(an_event(Flipper::Events::ToggleAdded).with_data(
        feature_name: "foo_bar",
      )).in_stream("FeatureToggle$foo_bar")
    end
  end
end
