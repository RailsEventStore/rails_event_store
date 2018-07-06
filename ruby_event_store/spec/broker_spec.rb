require 'spec_helper'
require 'ruby_event_store/spec/broker_lint'

module RubyEventStore
  module PubSub

    RSpec.describe Broker do
      it_behaves_like :broker, Broker
    end

  end
end
