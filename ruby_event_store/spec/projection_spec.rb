require 'spec_helper'

module RubyEventStore
  describe Projection do
    MoneyDeposited = Class.new(RubyEventStore::Event)
    MoneyWithdrawn = Class.new(RubyEventStore::Event)

    let(:event_store) { RubyEventStore::Facade.new(InMemoryRepository.new) }

    specify "reduce events from one stream" do
      stream_name = "Customer$123"
      event_store.publish_event(MoneyDeposited.new(amount: 10), stream_name)
      event_store.publish_event(MoneyDeposited.new(amount: 20), stream_name)
      event_store.publish_event(MoneyWithdrawn.new(amount: 5),  stream_name)
      account_balance = Projection.
        from_stream(stream_name).
        init( -> { { total: 0 } }).
        when(MoneyDeposited, ->(state, event) { state[:total] += event.amount }).
        when(MoneyWithdrawn, ->(state, event) { state[:total] -= event.amount }).
        call(event_store)
      expect(account_balance).to eq(total: 25)
    end

    specify "reduce events from many streams" do
      event_store.publish_event(MoneyDeposited.new(amount: 10), "Customer$1")
      event_store.publish_event(MoneyDeposited.new(amount: 20), "Customer$2")
      event_store.publish_event(MoneyWithdrawn.new(amount: 5),  "Customer$3")
      account_balance = Projection.
        from_stream("Customer$1", "Customer$3").
        init( -> { { total: 0 } }).
        when(MoneyDeposited, ->(state, event) { state[:total] += event.amount }).
        when(MoneyWithdrawn, ->(state, event) { state[:total] -= event.amount }).
        call(event_store)
      expect(account_balance).to eq(total: 5)
    end

    specify "reduce events from global stream" do
      event_store.publish_event(MoneyDeposited.new(amount: 10), "Customer$1")
      event_store.publish_event(MoneyDeposited.new(amount: 20), "Customer$2")
      event_store.publish_event(MoneyWithdrawn.new(amount: 5),  "Customer$3")
      account_balance = Projection.
        from_all_streams.
        init( -> { { total: 0 } }).
        when(MoneyDeposited, ->(state, event) { state[:total] += event.amount }).
        when(MoneyWithdrawn, ->(state, event) { state[:total] -= event.amount }).
        call(event_store)
      expect(account_balance).to eq(total: 25)
    end

    specify "at least one stream must be given" do
      expect { Projection.from_stream }.
        to raise_error(ArgumentError, "At least one stream must be given")
    end

    specify "empty hash is default inital state" do
      stream_name = "Customer$123"
      event_store.publish_event(MoneyDeposited.new(amount: 10), stream_name)
      event_store.publish_event(MoneyDeposited.new(amount: 20), stream_name)
      event_store.publish_event(MoneyWithdrawn.new(amount: 5),  stream_name)
      stats = Projection.
        from_stream(stream_name).
        when(MoneyDeposited, ->(state, event) { state[:last_deposit]    = event.amount }).
        when(MoneyWithdrawn, ->(state, event) { state[:last_withdrawal] = event.amount }).
        call(event_store)
      expect(stats).to eq(last_deposit: 20, last_withdrawal: 5)
    end

    specify "ignore unhandled events" do
      stream_name = "Customer$123"
      event_store.publish_event(MoneyDeposited.new(amount: 10), stream_name)
      event_store.publish_event(MoneyWithdrawn.new(amount: 2), stream_name)
      deposits = Projection.
        from_stream(stream_name).
        init( -> { { total: 0 } }).
        when(MoneyDeposited, ->(state, event) { state[:total] += event.amount }).
        call(event_store)
      expect(deposits).to eq(total: 10)
    end

    specify "subscribe to events" do
      stream_name = "Customer$123"
      deposits = Projection.
        from_stream(stream_name).
        init( -> { { total: 0 } }).
        when(MoneyDeposited, ->(state, event) { state[:total] += event.amount })
      event_store.subscribe(deposits, deposits.handled_events)
      event_store.publish_event(MoneyDeposited.new(amount: 10), stream_name)
      event_store.publish_event(MoneyDeposited.new(amount: 5), stream_name)
      expect(deposits.current_state).to eq(total: 15)
    end

    specify "using default constructor" do
      expect { Projection.new("Customer$123") }.to raise_error(NoMethodError, /private method `new'/)
    end
  end
end
