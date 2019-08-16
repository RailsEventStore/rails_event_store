require 'spec_helper'
require 'ruby_event_store/spec/subscription_store_lint'

module RubyEventStore
  RSpec.describe InMemorySubscriptionsStore do
    it_behaves_like :subscription_store, InMemorySubscriptionsStore.new
  end
end
