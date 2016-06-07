require 'spec_helper'
require 'ruby_event_store/spec/event_broker_lint'

module RubyEventStore
  describe PubSub::Broker do
    it_behaves_like :event_broker, PubSub::Broker.new
  end
end
