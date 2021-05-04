require "spec_helper"

module RubyEventStore
  ::RSpec.describe Flipper do
    let(:instrumenter) { ActiveSupport::Notifications }
    let(:event_store) { RubyEventStore::Client.new(repository: RubyEventStore::InMemoryRepository.new) }

    specify "enable hooks only into flipper notifications" do
      flipper = ::Flipper.new(::Flipper::Adapters::Memory.new, instrumenter: instrumenter)

      Flipper.enable(event_store)

      instrumenter.instrument('some_other_notification')

      expect(event_store).not_to have_published
    end

    specify "adding toggle" do
      flipper = ::Flipper.new(::Flipper::Adapters::Memory.new, instrumenter: instrumenter)

      Flipper.enable(event_store)
      flipper.add(:foo_bar)

      expect(event_store).to have_published(an_event(Flipper::Events::ToggleAdded).with_data(
        feature_name: "foo_bar",
      )).in_stream("FeatureToggle$foo_bar")
    end

    specify "adding toggle when already added" do
      flipper = ::Flipper.new(::Flipper::Adapters::Memory.new, instrumenter: instrumenter)
      Flipper.enable(event_store)
      flipper.add(:foo_bar)

      flipper.add(:foo_bar)

      expect(event_store).to have_published(an_event(Flipper::Events::ToggleAdded).with_data(
        feature_name: "foo_bar",
      )).in_stream("FeatureToggle$foo_bar")
    end

    specify "removing toggle" do
      flipper = ::Flipper.new(::Flipper::Adapters::Memory.new, instrumenter: instrumenter)

      Flipper.enable(event_store)
      flipper.add(:foo_bar)
      flipper.remove(:foo_bar)

      expect(event_store).to have_published(an_event(Flipper::Events::ToggleRemoved).with_data(
        feature_name: "foo_bar",
      )).in_stream("FeatureToggle$foo_bar")
    end

    specify "removing toggle when it was not added" do
      flipper = ::Flipper.new(::Flipper::Adapters::Memory.new, instrumenter: instrumenter)

      Flipper.enable(event_store)
      flipper.remove(:foo_bar)

      expect(event_store).to have_published(an_event(Flipper::Events::ToggleRemoved).with_data(
        feature_name: "foo_bar",
      )).in_stream("FeatureToggle$foo_bar")
    end

    specify "enabling toggle globally" do
      flipper = ::Flipper.new(::Flipper::Adapters::Memory.new, instrumenter: instrumenter)
      Flipper.enable(event_store)

      flipper.enable(:foo_bar)

      expect(event_store).to have_published(an_event(Flipper::Events::ToggleGloballyEnabled).with_data(
        feature_name: "foo_bar",
      )).in_stream("FeatureToggle$foo_bar")
    end

    specify "disabling toggle globally" do
      flipper = ::Flipper.new(::Flipper::Adapters::Memory.new, instrumenter: instrumenter)
      Flipper.enable(event_store)

      flipper.disable(:foo_bar)

      expect(event_store).to have_published(an_event(Flipper::Events::ToggleGloballyDisabled).with_data(
        feature_name: "foo_bar",
      )).in_stream("FeatureToggle$foo_bar")
    end

    specify "enabling toggle for actor" do
      flipper = ::Flipper.new(::Flipper::Adapters::Memory.new, instrumenter: instrumenter)
      Flipper.enable(event_store)

      actor = OpenStruct.new(flipper_id: "User:123")
      flipper.enable_actor(:foo_bar, actor)

      expect(event_store).to have_published(an_event(Flipper::Events::ToggleEnabledForActor).with_data(
        feature_name: "foo_bar",
        actor: "User:123",
      )).in_stream("FeatureToggle$foo_bar")
    end

    specify "disabling toggle for actor" do
      flipper = ::Flipper.new(::Flipper::Adapters::Memory.new, instrumenter: instrumenter)
      Flipper.enable(event_store)

      actor = OpenStruct.new(flipper_id: "User:123")
      flipper.disable_actor(:foo_bar, actor)

      expect(event_store).to have_published(an_event(Flipper::Events::ToggleDisabledForActor).with_data(
        feature_name: "foo_bar",
        actor: "User:123",
      )).in_stream("FeatureToggle$foo_bar")
    end
  end
end
