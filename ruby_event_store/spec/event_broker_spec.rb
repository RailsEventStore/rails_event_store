require 'spec_helper'
require 'ruby_event_store/spec/event_broker_lint'

module RubyEventStore
  module PubSub
    RSpec.describe Broker do
      it_behaves_like :event_broker, Broker
    end
  end
end
