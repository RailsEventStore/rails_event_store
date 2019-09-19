require 'spec_helper'
require 'ruby_event_store/spec/subscriptions_lint'

module RubyEventStore
  RSpec.describe Subscriptions do
    it_behaves_like :subscriptions, Subscriptions

    it do
      subscriptions = Subscriptions.new
      expect { subscriptions.add_subscription(-> {}, ["Test1DomainEvent"]) }.to output(<<~MSG).to_stderr
        Method `add_subscription` has been deprecated. Use `add` method instead.
      MSG
      expect { subscriptions.add_global_subscription(-> {}) }.to output(<<~MSG).to_stderr
        Method `add_global_subscription` has been deprecated. Use `add` method instead.
      MSG
      expect { subscriptions.add_thread_subscription(-> {}, ["Test1DomainEvent"]) }.to output(<<~MSG).to_stderr
        Method `add_thread_subscription` has been deprecated. Use `add` method instead.
      MSG
      expect { subscriptions.add_thread_global_subscription(-> {}) }.to output(<<~MSG).to_stderr
        Method `add_thread_global_subscription` has been deprecated. Use `add` method instead.
      MSG
    end
  end
end
