module RubyEventStore
  # @private
  FirstEvent = Class.new(RubyEventStore::Event)
  # @private
  SecondEvent = Class.new(RubyEventStore::Event)
end

module RubyEventStore
  RSpec.shared_examples :subscription_store do |subscription_store|
    specify do
      expect(subscription_store.all).to eq []
      expect(subscription_store.all_for(FirstEvent)).to eq []
      expect(subscription_store.all_for(SecondEvent)).to eq []
      expect(subscription_store.all_for(RubyEventStore::GLOBAL_SUBSCRIPTION)).to eq []

      global = RubyEventStore::Subscription.new(-> { }, store: subscription_store)
      first  = RubyEventStore::Subscription.new(-> { }, [FirstEvent], store: subscription_store)
      second = RubyEventStore::Subscription.new(-> { }, [FirstEvent, SecondEvent], store: subscription_store)

      expect(subscription_store.all).to match_array [global, first, second]

      expect(subscription_store.all_for(FirstEvent)).to match_array [first, second]
      expect(subscription_store.all_for(SecondEvent)).to match_array [second]
      expect(subscription_store.all_for(RubyEventStore::GLOBAL_SUBSCRIPTION)).to match_array [global]

      global.unsubscribe
      expect(subscription_store.all_for(RubyEventStore::GLOBAL_SUBSCRIPTION)).to eq []
      expect(subscription_store.all).to match_array [first, second]

      first.unsubscribe
      expect(subscription_store.all_for(FirstEvent)).to match_array [second]
      expect(subscription_store.all_for(SecondEvent)).to match_array [second]
      expect(subscription_store.all).to match_array [second]

      second.unsubscribe
      expect(subscription_store.all_for(FirstEvent)).to eq []
      expect(subscription_store.all_for(SecondEvent)).to eq []
      expect(subscription_store.all).to eq []
    end
  end
end
