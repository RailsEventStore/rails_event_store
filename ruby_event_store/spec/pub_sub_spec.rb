require 'spec_helper'

module RubyEventStore
  RSpec.describe PubSub do
    describe "Subscriptions" do
      specify do
        expect{RubyEventStore::PubSub::Subscriptions}.to output(<<~MSG).to_stderr
          `RubyEventStore::PubSub::Subscriptions` has been deprecated. Use `RubyEventStore::Subscriptions` instead.
        MSG
      end

      specify do
        silence_warnings { expect(PubSub::Subscriptions).to eq(Subscriptions) }
      end
    end

    describe "Broker" do
      specify do
        expect{RubyEventStore::PubSub::Broker}.to output(<<~MSG).to_stderr
        `RubyEventStore::PubSub::Broker` has been deprecated. Use `RubyEventStore::Broker` instead.
          MSG
      end

      specify do
        silence_warnings { expect(PubSub::Broker).to eq(Broker) }
      end
    end

    describe "Dispatcher" do
      specify do
        expect{RubyEventStore::PubSub::Dispatcher}.to output(<<~MSG).to_stderr
        `RubyEventStore::PubSub::Dispatcher` has been deprecated. Use `RubyEventStore::Dispatcher` instead.
          MSG
      end

      specify do
        silence_warnings { expect(PubSub::Dispatcher).to eq(Dispatcher) }
      end
    end

    specify do
      expect { PubSub::NoSuchConst }.to raise_error(NameError)
    end
  end
end
