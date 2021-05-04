require "spec_helper"

module RubyEventStore
  ::RSpec.describe Flipper do
    let(:instrumenter) { ActiveSupport::Notifications }
    let(:event_store) { RubyEventStore::Client.new(repository: RubyEventStore::InMemoryRepository.new) }
    let(:flipper) { ::Flipper.new(::Flipper::Adapters::Memory.new, instrumenter: instrumenter) }

    specify "enable hooks only into flipper notifications" do
      Flipper.enable(event_store)

      instrumenter.instrument('some_other_notification')

      expect(event_store).not_to have_published
    end

    specify "adding toggle" do
      Flipper.enable(event_store)
      flipper.add(:foo_bar)

      expect(event_store).to have_published(an_event(Flipper::Events::ToggleAdded).with_data(
        feature_name: "foo_bar",
      )).in_stream("FeatureToggle$foo_bar")
    end

    specify "adding toggle when already added" do
      Flipper.enable(event_store)
      flipper.add(:foo_bar)

      flipper.add(:foo_bar)

      expect(event_store).to have_published(an_event(Flipper::Events::ToggleAdded).with_data(
        feature_name: "foo_bar",
      )).in_stream("FeatureToggle$foo_bar")
    end

    specify "removing toggle" do
      Flipper.enable(event_store)
      flipper.add(:foo_bar)
      flipper.remove(:foo_bar)

      expect(event_store).to have_published(an_event(Flipper::Events::ToggleRemoved).with_data(
        feature_name: "foo_bar",
      )).in_stream("FeatureToggle$foo_bar")
    end

    specify "removing toggle when it was not added" do

      Flipper.enable(event_store)
      flipper.remove(:foo_bar)

      expect(event_store).to have_published(an_event(Flipper::Events::ToggleRemoved).with_data(
        feature_name: "foo_bar",
      )).in_stream("FeatureToggle$foo_bar")
    end

    specify "enabling toggle globally" do
      Flipper.enable(event_store)

      flipper.enable(:foo_bar)

      expect(event_store).to have_published(an_event(Flipper::Events::ToggleGloballyEnabled).with_data(
        feature_name: "foo_bar",
      )).in_stream("FeatureToggle$foo_bar")
    end

    specify "disabling toggle globally" do
      Flipper.enable(event_store)

      flipper.disable(:foo_bar)

      expect(event_store).to have_published(an_event(Flipper::Events::ToggleGloballyDisabled).with_data(
        feature_name: "foo_bar",
      )).in_stream("FeatureToggle$foo_bar")
    end

    specify "enabling toggle for actor" do
      Flipper.enable(event_store)

      actor = OpenStruct.new(flipper_id: "User:123")
      flipper.enable_actor(:foo_bar, actor)

      expect(event_store).to have_published(an_event(Flipper::Events::ToggleEnabledForActor).with_data(
        feature_name: "foo_bar",
        actor: "User:123",
      )).in_stream("FeatureToggle$foo_bar")
    end

    specify "disabling toggle for actor" do
      Flipper.enable(event_store)

      actor = OpenStruct.new(flipper_id: "User:123")
      flipper.disable_actor(:foo_bar, actor)

      expect(event_store).to have_published(an_event(Flipper::Events::ToggleDisabledForActor).with_data(
        feature_name: "foo_bar",
        actor: "User:123",
      )).in_stream("FeatureToggle$foo_bar")
    end

    specify "enabling toggle for group" do
      Flipper.enable(event_store)

      flipper.enable_group(:foo_bar, :admins)

      expect(event_store).to have_published(an_event(Flipper::Events::ToggleEnabledForGroup).with_data(
        feature_name: "foo_bar",
        group: "admins",
      )).in_stream("FeatureToggle$foo_bar")
    end

    specify "disabling toggle for group" do
      Flipper.enable(event_store)

      flipper.disable_group(:foo_bar, :admins)

      expect(event_store).to have_published(an_event(Flipper::Events::ToggleDisabledForGroup).with_data(
        feature_name: "foo_bar",
        group: "admins",
      )).in_stream("FeatureToggle$foo_bar")
    end

    specify "enabling toggle for percentage of actors" do
      Flipper.enable(event_store)

      flipper.enable_percentage_of_actors(:foo_bar, 2)

      expect(event_store).to have_published(an_event(Flipper::Events::ToggleEnabledForPercentageOfActors).with_data(
        feature_name: "foo_bar",
        percentage: 2,
      )).in_stream("FeatureToggle$foo_bar")
    end

    specify "disabling toggle for percentage of actors" do
      Flipper.enable(event_store)

      flipper.disable_percentage_of_actors(:foo_bar)

      expect(event_store).to have_published(an_event(Flipper::Events::ToggleDisabledForPercentageOfActors).with_data(
        feature_name: "foo_bar",
      )).in_stream("FeatureToggle$foo_bar")
    end

    specify "enabling toggle for percentage of time" do
      Flipper.enable(event_store)

      flipper.enable_percentage_of_time(:foo_bar, 13)

      expect(event_store).to have_published(an_event(Flipper::Events::ToggleEnabledForPercentageOfTime).with_data(
        feature_name: "foo_bar",
        percentage: 13,
      )).in_stream("FeatureToggle$foo_bar")
    end

    specify "disabling toggle for percentage of time" do
      Flipper.enable(event_store)

      flipper.disable_percentage_of_time(:foo_bar)

      expect(event_store).to have_published(an_event(Flipper::Events::ToggleDisabledForPercentageOfTime).with_data(
        feature_name: "foo_bar",
      )).in_stream("FeatureToggle$foo_bar")
    end

    specify "dont raise error for operations which dont publish event" do
      Flipper.enable(event_store)

      expect do
        flipper.enabled?(:foo_bar)
      end.not_to raise_error
      expect(event_store).not_to have_published
    end
  end
end
