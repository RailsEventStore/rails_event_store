# frozen_string_literal: true

require 'spec_helper'
require 'ruby_event_store/spec/subscription_store_lint'
require 'active_support/notifications'

module RubyEventStore
  RSpec.describe InstrumentedSubscriptionsStore do
    it_behaves_like :subscription_store, InstrumentedSubscriptionsStore.new(InMemorySubscriptionsStore.new, ActiveSupport::Notifications)

    describe "#add" do
      specify "wraps around original implementation" do
        some_store = spy
        instrumented_store = InstrumentedSubscriptionsStore.new(some_store, ActiveSupport::Notifications)
        subscription = Subscription.new(-> { })

        instrumented_store.add(subscription)

        expect(some_store).to have_received(:add).with(subscription)
      end

      specify "instruments" do
        instrumented_store = InstrumentedSubscriptionsStore.new(spy, ActiveSupport::Notifications)
        subscribe_to("add.subscription_store.rails_event_store") do |notification_calls|
          subscription = Subscription.new(-> { })

          instrumented_store.add(subscription)

          expect(notification_calls).to eq([
            { subscription: subscription }
          ])
        end
      end
    end

    describe "#delete" do
      specify "wraps around original implementation" do
        some_store = spy
        instrumented_store = InstrumentedSubscriptionsStore.new(some_store, ActiveSupport::Notifications)
        subscription = Subscription.new(-> { })

        instrumented_store.delete(subscription)

        expect(some_store).to have_received(:delete).with(subscription)
      end

      specify "instruments" do
        instrumented_store = InstrumentedSubscriptionsStore.new(spy, ActiveSupport::Notifications)
        subscribe_to("delete.subscription_store.rails_event_store") do |notification_calls|
          subscription = Subscription.new(-> { })

          instrumented_store.delete(subscription)

          expect(notification_calls).to eq([
            { subscription: subscription }
          ])
        end
      end
    end

    describe "#all_for" do
      specify "wraps around original implementation" do
        some_store = spy
        instrumented_store = InstrumentedSubscriptionsStore.new(some_store, ActiveSupport::Notifications)

        instrumented_store.all_for(TestEvent)

        expect(some_store).to have_received(:all_for).with(TestEvent)
      end
    end

    describe "#all" do
      specify "wraps around original implementation" do
        some_store = spy
        instrumented_store = InstrumentedSubscriptionsStore.new(some_store, ActiveSupport::Notifications)

        instrumented_store.all

        expect(some_store).to have_received(:all)
      end
    end

    def subscribe_to(name)
      received_payloads = []
      callback = ->(_name, _start, _finish, _id, payload) { received_payloads << payload }
      ActiveSupport::Notifications.subscribed(callback, name) do
        yield received_payloads
      end
    end
  end
end
