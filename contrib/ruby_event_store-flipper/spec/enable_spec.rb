require "spec_helper"

module RubyEventStore
  ::RSpec.describe Flipper do
    specify "enable hooks only into flipper notifications" do
      event_store = RubyEventStore::Client.new(repository: RubyEventStore::InMemoryRepository.new)
      flipper = ::Flipper.new(::Flipper::Adapters::Memory.new, instrumenter: ActiveSupport::Notifications)

      Flipper.enable(event_store)

      ActiveSupport::Notifications.instrument('some_other_notification')

      expect(event_store).not_to have_published
    end

    specify "adding toggle" do
      event_store = RubyEventStore::Client.new(repository: RubyEventStore::InMemoryRepository.new)
      flipper = ::Flipper.new(::Flipper::Adapters::Memory.new, instrumenter: ActiveSupport::Notifications)

      Flipper.enable(event_store)
      flipper.add(:foo_bar)

      expect(event_store).to have_published(an_event(Flipper::Events::ToggleAdded).with_data(
        feature_name: "foo_bar",
      )).in_stream("FeatureToggle$foo_bar")
    end

    specify "adding toggle when already added" do
      event_store = RubyEventStore::Client.new(repository: RubyEventStore::InMemoryRepository.new)
      flipper = ::Flipper.new(::Flipper::Adapters::Memory.new, instrumenter: ActiveSupport::Notifications)
      Flipper.enable(event_store)
      flipper.add(:foo_bar)

      flipper.add(:foo_bar)

      expect(event_store).to have_published(an_event(Flipper::Events::ToggleAdded).with_data(
        feature_name: "foo_bar",
      )).in_stream("FeatureToggle$foo_bar")
    end

    specify "removing toggle" do
      event_store = RubyEventStore::Client.new(repository: RubyEventStore::InMemoryRepository.new)
      flipper = ::Flipper.new(::Flipper::Adapters::Memory.new, instrumenter: ActiveSupport::Notifications)

      Flipper.enable(event_store)
      flipper.add(:foo_bar)
      flipper.remove(:foo_bar)

      expect(event_store).to have_published(an_event(Flipper::Events::ToggleRemoved).with_data(
        feature_name: "foo_bar",
      )).in_stream("FeatureToggle$foo_bar")
    end

    specify "removing toggle when it was not added" do
      event_store = RubyEventStore::Client.new(repository: RubyEventStore::InMemoryRepository.new)
      flipper = ::Flipper.new(::Flipper::Adapters::Memory.new, instrumenter: ActiveSupport::Notifications)

      Flipper.enable(event_store)
      flipper.remove(:foo_bar)

      expect(event_store).to have_published(an_event(Flipper::Events::ToggleRemoved).with_data(
        feature_name: "foo_bar",
      )).in_stream("FeatureToggle$foo_bar")
    end
  end
end
