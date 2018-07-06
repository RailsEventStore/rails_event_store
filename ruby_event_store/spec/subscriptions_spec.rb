require 'spec_helper'
require 'ruby_event_store/spec/subscriptions_lint'

module RubyEventStore
  module PubSub
    RSpec.describe Subscriptions do
      it_behaves_like :subscriptions, Subscriptions
    end
  end
end
