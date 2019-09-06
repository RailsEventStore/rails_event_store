require 'spec_helper'
require 'ruby_event_store/spec/subscription_store_lint'

module RubyEventStore
  RSpec.describe InMemorySubscriptionsStore do
    it_behaves_like :subscription_store, InMemorySubscriptionsStore.new

    it { expect(InMemorySubscriptionsStore.new.all).to eq [] }
    it { expect(InMemorySubscriptionsStore.new.all_for('not-existing')).to eq [] }
    it {
      store = InMemorySubscriptionsStore.new
      subscription = RubyEventStore::Subscription.new(-> { }, [TestEvent])
      store.add(subscription)
      expect(store.all_for('not-existing')).to eq []
      expect(store.all_for(TestEvent)).to eq [subscription]
    }
  end
end
