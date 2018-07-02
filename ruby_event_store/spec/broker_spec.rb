require 'spec_helper'
require 'ruby_event_store/spec/broker_lint'

module RubyEventStore
  module PubSub

    RSpec.describe Broker do
      it_behaves_like :broker, Broker

      it do
        broker = Broker.new
        expect(broker.subscriptions).to be_instance_of(::RubyEventStore::PubSub::Subscriptions)
        expect(broker.dispatcher).to be_instance_of(::RubyEventStore::PubSub::Dispatcher)
      end
    end

  end
end
