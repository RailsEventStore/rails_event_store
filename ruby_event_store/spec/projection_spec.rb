require 'spec_helper'

module RubyEventStore
  RSpec.describe Projection do
    MoneyDeposited = Class.new(RubyEventStore::Event)
    MoneyWithdrawn = Class.new(RubyEventStore::Event)

    let(:event_store) { RubyEventStore::Client.new(repository: InMemoryRepository.new, mapper: Mappers::NullMapper.new) }

    specify "reduce events from one stream" do
      stream_name = "Customer$123"
      event_store.publish(MoneyDeposited.new(data: { amount: 10 }), stream_name: stream_name)
      event_store.publish(MoneyDeposited.new(data: { amount: 20 }), stream_name: stream_name)
      event_store.publish(MoneyWithdrawn.new(data: { amount: 5 }),  stream_name: stream_name)
      account_balance = Projection
        .from_stream(stream_name)
        .init( -> { { total: 0 } })
        .when(MoneyDeposited, ->(state, event) { state[:total] += event.data[:amount] })
        .when(MoneyWithdrawn, ->(state, event) { state[:total] -= event.data[:amount] })
        .run(event_store)
      expect(account_balance).to eq(total: 25)
    end

    specify "reduce events from many streams" do
      event_store.publish(MoneyDeposited.new(data: { amount: 10 }), stream_name: "Customer$1")
      event_store.publish(MoneyDeposited.new(data: { amount: 20 }), stream_name: "Customer$2")
      event_store.publish(MoneyWithdrawn.new(data: { amount: 5 }),  stream_name: "Customer$3")
      account_balance = Projection
        .from_stream("Customer$1", "Customer$3")
        .init( -> { { total: 0 } })
        .when(MoneyDeposited, ->(state, event) { state[:total] += event.data[:amount] })
        .when(MoneyWithdrawn, ->(state, event) { state[:total] -= event.data[:amount] })
        .run(event_store)
      expect(account_balance).to eq(total: 5)
    end

    specify "raises proper errors when wrong argument were pass (stream mode)" do
      projection = Projection.from_stream("Customer$1", "Customer$2")
      expect {
        projection.run(event_store, start: :last)
      }.to raise_error ArgumentError, 'Start must be an array with event ids'
      expect {
        projection.run(event_store, start: 0.7)
      }.to raise_error ArgumentError, 'Start must be an array with event ids'
      expect {
        projection.run(event_store, start: [SecureRandom.uuid])
      }.to raise_error ArgumentError, 'Start must be an array with event ids'
    end

    specify "take events from all streams" do
      event_store.publish(MoneyDeposited.new(data: { amount: 1 }), stream_name: "Customer$1")
      event_store.publish(MoneyDeposited.new(data: { amount: 1 }), stream_name: "Customer$2")
      event_store.publish(MoneyDeposited.new(data: { amount: 1 }), stream_name: "Customer$3")
      event_store.publish(MoneyWithdrawn.new(data: { amount: 2 }), stream_name: "Customer$4")

      account_balance = Projection
        .from_all_streams
        .init( -> { { total: 0 } })
        .when(MoneyDeposited, ->(state, event) { state[:total] += event.data[:amount] })
        .when(MoneyWithdrawn, ->(state, event) { state[:total] -= event.data[:amount] })

      expect(account_balance.run(event_store)).to eq(total: 1)
    end

    specify "raises proper errors when wrong argument were pass (all streams mode)" do
      projection = Projection.from_all_streams
      expect {
        projection.run(event_store, start: :last)
      }.to raise_error ArgumentError, 'Start must be valid event id'
      expect {
        projection.run(event_store, start: 0.7)
      }.to raise_error ArgumentError, 'Start must be valid event id'
      expect {
        projection.run(event_store, start: [SecureRandom.uuid])
      }.to raise_error ArgumentError, 'Start must be valid event id'
    end

    specify "empty hash is default inital state" do
      stream_name = "Customer$123"
      event_store.publish(MoneyDeposited.new(data: { amount: 10 }), stream_name: stream_name)
      event_store.publish(MoneyDeposited.new(data: { amount: 20 }), stream_name: stream_name)
      event_store.publish(MoneyWithdrawn.new(data: { amount: 5 }),  stream_name: stream_name)
      stats = Projection
        .from_stream(stream_name)
        .when(MoneyDeposited, ->(state, event) { state[:last_deposit]    = event.data[:amount] })
        .when(MoneyWithdrawn, ->(state, event) { state[:last_withdrawal] = event.data[:amount] })
        .run(event_store)
      expect(stats).to eq(last_deposit: 20, last_withdrawal: 5)
    end

    specify "ignore unhandled events" do
      stream_name = "Customer$123"
      event_store.publish(MoneyDeposited.new(data: { amount: 10 }), stream_name: stream_name)
      event_store.publish(MoneyWithdrawn.new(data: { amount: 2 }), stream_name: stream_name)
      deposits = Projection
        .from_stream(stream_name)
        .init( -> { { total: 0 } })
        .when(MoneyDeposited, ->(state, event) { state[:total] += event.data[:amount] })
        .run(event_store)
      expect(deposits).to eq(total: 10)
    end

    specify "subsrcibe one handler to many events" do
      stream_name = "Customer$123"
      event_store.publish(MoneyDeposited.new(data: { amount: 10 }), stream_name: stream_name)
      event_store.publish(MoneyWithdrawn.new(data: { amount: 2 }), stream_name: stream_name)
      cashflow = Projection
        .from_stream(stream_name)
        .init( -> { { total: 0 } })
        .when([MoneyDeposited, MoneyWithdrawn], ->(state, event) { state[:total] += event.data[:amount] })
        .run(event_store)
      expect(cashflow).to eq(total: 12)
    end

    specify "subscribe to events" do
      stream_name = "Customer$123"
      deposits = Projection
        .from_stream(stream_name)
        .init( -> { { total: 0 } })
        .when(MoneyDeposited, ->(state, event) { state[:total] += event.data[:amount] })
      event_store.subscribe(deposits, to: deposits.handled_events)
      event_store.publish(MoneyDeposited.new(data: { amount: 10 }), stream_name: stream_name)
      event_store.publish(MoneyDeposited.new(data: { amount: 5 }), stream_name: stream_name)
      expect(deposits.current_state).to eq(total: 15)
    end

    specify "using default constructor" do
      expect { Projection.new("Customer$123") }.to raise_error(NoMethodError, /private method `new'/)
    end

    specify "at least one stream must be given" do
      expect { Projection.from_stream }
        .to raise_error(ArgumentError, "At least one stream must be given")
    end

    specify "all events from the stream must be read (starting from begining of the stream)" do
      stream_name = "Customer$123"
      event_store.publish(MoneyDeposited.new(data: { amount: 10 }), stream_name: stream_name)
      event_store.publish(MoneyWithdrawn.new(data: { amount: 2 }), stream_name: stream_name)
      event_store.publish(MoneyDeposited.new(data: { amount: 4 }), stream_name: stream_name)
      event_store.publish(MoneyWithdrawn.new(data: { amount: 3 }), stream_name: stream_name)
      event_store.publish(MoneyDeposited.new(data: { amount: 5 }), stream_name: stream_name)
      balance = Projection
        .from_stream(stream_name)
        .init( -> { { total: 0 } })
        .when([MoneyDeposited], ->(state, event) { state[:total] += event.data[:amount] })
        .when([MoneyWithdrawn], ->(state, event) { state[:total] -= event.data[:amount] })
        .run(event_store, count: 2)
      expect(balance).to eq(total: 14)
    end

    specify "all events from the stream must be read (starting from given event)" do
      stream_name = "Customer$123"
      event_store.publish(MoneyDeposited.new(data: { amount: 10 }), stream_name: stream_name)
      event_store.publish(starting = MoneyWithdrawn.new(data: { amount: 2 }), stream_name: stream_name)
      event_store.publish(MoneyDeposited.new(data: { amount: 4 }), stream_name: stream_name)
      event_store.publish(MoneyWithdrawn.new(data: { amount: 3 }), stream_name: stream_name)
      event_store.publish(MoneyDeposited.new(data: { amount: 5 }), stream_name: stream_name)
      balance = Projection
        .from_stream(stream_name)
        .init( -> { { total: 0 } })
        .when([MoneyDeposited], ->(state, event) { state[:total] += event.data[:amount] })
        .when([MoneyWithdrawn], ->(state, event) { state[:total] -= event.data[:amount] })
        .run(event_store, start: [starting.event_id], count: 2)
      expect(balance).to eq(total: 6)
    end

    specify "all events from all streams must be read (starting from begining of each stream)" do
      event_store.publish(MoneyDeposited.new(data: { amount: 10 }), stream_name: "Customer$123")
      event_store.publish(MoneyWithdrawn.new(data: { amount: 2 }), stream_name: "Customer$123")
      event_store.publish(MoneyDeposited.new(data: { amount: 4 }), stream_name: "Customer$234")
      event_store.publish(MoneyWithdrawn.new(data: { amount: 3 }), stream_name: "Customer$234")
      event_store.publish(MoneyDeposited.new(data: { amount: 5 }), stream_name: "Customer$345")
      balance = Projection
        .from_all_streams
        .init( -> { { total: 0 } })
        .when([MoneyDeposited], ->(state, event) { state[:total] += event.data[:amount] })
        .when([MoneyWithdrawn], ->(state, event) { state[:total] -= event.data[:amount] })
        .run(event_store, count: 2)
      expect(balance).to eq(total: 14)
    end

    specify "all events from all streams must be read (starting from given event)" do
      event_store.publish(MoneyDeposited.new(data: { amount: 10 }), stream_name: "Customer$123")
      event_store.publish(starting = MoneyWithdrawn.new(data: { amount: 2 }), stream_name: "Customer$123")
      event_store.publish(MoneyDeposited.new(data: { amount: 4 }), stream_name: "Customer$234")
      event_store.publish(MoneyWithdrawn.new(data: { amount: 3 }), stream_name: "Customer$234")
      event_store.publish(MoneyDeposited.new(data: { amount: 5 }), stream_name: "Customer$345")
      balance = Projection
        .from_all_streams
        .init( -> { { total: 0 } })
        .when([MoneyDeposited], ->(state, event) { state[:total] += event.data[:amount] })
        .when([MoneyWithdrawn], ->(state, event) { state[:total] -= event.data[:amount] })
        .run(event_store, start: starting.event_id, count: 2)
      expect(balance).to eq(total: 6)
    end

    specify do
      repository = event_store.send(:repository)
      mapper     = event_store.send(:mapper)
      specification = Specification.new(SpecificationReader.new(repository, mapper))
      expected = specification.in_batches(2).result
      expect(repository).to receive(:read).with(expected).and_return([])
      Projection.from_all_streams.run(event_store, count: 2)
    end

    specify do
      repository = event_store.send(:repository)
      mapper     = event_store.send(:mapper)
      specification = Specification.new(SpecificationReader.new(repository, mapper))
      expected = specification.in_batches(2).stream("FancyStream").result
      expect(repository).to receive(:read).with(expected).and_return([])
      Projection.from_stream("FancyStream").run(event_store, count: 2)
    end
  end
end
