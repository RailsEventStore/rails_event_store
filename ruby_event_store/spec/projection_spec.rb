require "spec_helper"

module RubyEventStore
  ::RSpec.describe Projection do
    MoneyDeposited = Class.new(Event)
    MoneyWithdrawn = Class.new(Event)
    EventToBeSkipped = Class.new(Event)
    MoneyLost = Class.new(Event)
    MoneyInvested = Class.new(Event)

    let(:event_store) { Client.new(repository: repository, mapper: mapper) }
    let(:mapper) { Mappers::Default.new }
    let(:repository) { InMemoryRepository.new }
    let(:stream_name) { "Customer$123" }

    specify "reduce events from one stream" do
      event_store.append(
        [
          MoneyDeposited.new(data: { amount: 10 }),
          MoneyDeposited.new(data: { amount: 20 }),
          MoneyWithdrawn.new(data: { amount: 5 })
        ],
        stream_name: stream_name
      )

      account_balance =
        Projection
          .new(0)
          .on(MoneyDeposited) { |state, event| state += event.data[:amount] }
          .on(MoneyWithdrawn) { |state, event| state -= event.data[:amount] }
          .call(event_store.read)
      expect(account_balance).to eq(25)
    end

    specify "reduce events from many streams" do
      event_store.append(MoneyDeposited.new(data: { amount: 10 }), stream_name: "Customer$1")
      event_store.append(MoneyDeposited.new(data: { amount: 20 }), stream_name: "Customer$2")
      event_store.append(MoneyWithdrawn.new(data: { amount: 5 }), stream_name: "Customer$3")

      account_balance =
        Projection
          .new(0)
          .on(MoneyDeposited) { |state, event| state += event.data[:amount] }
          .on(MoneyWithdrawn) { |state, event| state -= event.data[:amount] }
          .call(event_store.read.stream("Customer$1"), event_store.read.stream("Customer$3"))
      expect(account_balance).to eq(5)
    end

    specify "take events from all streams" do
      event_store.append(MoneyDeposited.new(data: { amount: 1 }), stream_name: "Customer$1")
      event_store.append(MoneyDeposited.new(data: { amount: 1 }), stream_name: "Customer$2")
      event_store.append(MoneyDeposited.new(data: { amount: 1 }), stream_name: "Customer$3")
      event_store.append(MoneyWithdrawn.new(data: { amount: 2 }), stream_name: "Customer$4")

      account_balance =
        Projection
          .new(0)
          .on(MoneyDeposited) { |state, event| state += event.data[:amount] }
          .on(MoneyWithdrawn) { |state, event| state -= event.data[:amount] }
          .call(event_store.read)

      expect(account_balance).to eq(1)
    end

    specify "state could be more complex than simple value" do
      event_store.append(
        [
          MoneyDeposited.new(data: { amount: 10 }),
          MoneyDeposited.new(data: { amount: 20 }),
          MoneyWithdrawn.new(data: { amount: 5 })
        ],
        stream_name: stream_name
      )

      stats =
        Projection.new({})
          .on(MoneyDeposited) { |state, event| state[:last_deposit] = event.data[:amount]; state }
          .on(MoneyWithdrawn) { |state, event| state[:last_withdrawal] = event.data[:amount]; state }
          .call(event_store.read.stream(stream_name))
      expect(stats).to eq(last_deposit: 20, last_withdrawal: 5)
    end

    specify "ignore unhandled events" do
      event_store.append(
        [MoneyDeposited.new(data: { amount: 10 }), MoneyWithdrawn.new(data: { amount: 2 })],
        stream_name: stream_name
      )

      deposits =
        Projection
          .new(0)
          .on(MoneyDeposited) { |state, event| state += event.data[:amount] }
          .call(event_store.read.stream(stream_name))
      expect(deposits).to eq(10)
    end

    specify "subsrcibe one handler to many events" do
      event_store.append(
        [MoneyDeposited.new(data: { amount: 10 }), MoneyWithdrawn.new(data: { amount: 2 })],
        stream_name: stream_name
      )

      cashflow =
        Projection
          .new(0)
          .on(MoneyDeposited, MoneyWithdrawn) { |state, event| state += event.data[:amount] }
          .call(event_store.read.stream(stream_name))
      expect(cashflow).to eq(12)
    end

    specify "all events from the stream must be read (starting from begining of the stream)" do
      event_store.append(
        [
          MoneyDeposited.new(data: { amount: 10 }),
          MoneyWithdrawn.new(data: { amount: 2 }),
          MoneyDeposited.new(data: { amount: 4 }),
          MoneyWithdrawn.new(data: { amount: 3 }),
          MoneyDeposited.new(data: { amount: 5 })
        ],
        stream_name: stream_name
      )

      balance =
        Projection
          .new(0)
          .on(MoneyDeposited) { |state, event| state += event.data[:amount] }
          .on(MoneyWithdrawn) { |state, event| state -= event.data[:amount] }
          .call(event_store.read.stream(stream_name).in_batches(2))
      expect(balance).to eq(14)
    end

    specify "all events from the stream must be read (starting from given event)" do
      event_store.append(
        [
          MoneyDeposited.new(data: { amount: 10 }),
          starting = MoneyWithdrawn.new(data: { amount: 2 }),
          MoneyDeposited.new(data: { amount: 4 }),
          MoneyWithdrawn.new(data: { amount: 3 }),
          MoneyDeposited.new(data: { amount: 5 })
        ],
        stream_name: stream_name
      )

      balance =
        Projection
          .new(0)
          .on(MoneyDeposited) { |state, event| state += event.data[:amount] }
          .on(MoneyWithdrawn) { |state, event| state -= event.data[:amount] }
          .call(event_store.read.stream(stream_name).from(starting.event_id).in_batches(2))
      expect(balance).to eq(6)
    end

    specify "all events from all streams must be read (starting from begining of each stream)" do
      event_store.append(MoneyDeposited.new(data: { amount: 10 }), stream_name: stream_name)
      event_store.append(MoneyWithdrawn.new(data: { amount: 2 }), stream_name: stream_name)
      event_store.append(MoneyDeposited.new(data: { amount: 4 }), stream_name: "Customer$2")
      event_store.append(MoneyWithdrawn.new(data: { amount: 3 }), stream_name: "Customer$2")
      event_store.append(MoneyDeposited.new(data: { amount: 5 }), stream_name: "Customer$3")

      balance =
        Projection
          .new(0)
          .on(MoneyDeposited) { |state, event| state += event.data[:amount] }
          .on(MoneyWithdrawn) { |state, event| state -= event.data[:amount] }
          .call(event_store.read.in_batches(2))
      expect(balance).to eq(14)
    end

    specify "all events from all streams must be read (starting from given event)" do
      event_store.append(MoneyDeposited.new(data: { amount: 10 }), stream_name: stream_name)
      event_store.append(starting = MoneyWithdrawn.new(data: { amount: 2 }), stream_name: stream_name)
      event_store.append(MoneyDeposited.new(data: { amount: 4 }), stream_name: "Customer$2")
      event_store.append(MoneyWithdrawn.new(data: { amount: 3 }), stream_name: "Customer$2")
      event_store.append(MoneyDeposited.new(data: { amount: 5 }), stream_name: "Customer$3")

      balance =
        Projection
          .new(0)
          .on(MoneyDeposited) { |state, event| state += event.data[:amount] }
          .on(MoneyWithdrawn) { |state, event| state -= event.data[:amount] }
          .call(event_store.read.from(starting.event_id).in_batches(2))
      expect(balance).to eq(6)
    end

    specify "only events that have handlers must be read" do
      event_store.publish(
        [
          EventToBeSkipped.new,
          MoneyDeposited.new(data: { amount: 10 }),
          MoneyLost.new(data: { amount: 1 }),
          MoneyWithdrawn.new(data: { amount: 3 })
        ],
        stream_name: "Customer$234"
      )

      specification = Specification.new(SpecificationReader.new(repository, mapper))
      expected = specification.in_batches(100).of_type([MoneyDeposited, MoneyWithdrawn, MoneyLost]).result
      expect(repository).to receive(:read).with(expected).and_call_original

      balance =
        Projection
          .new(0)
          .on(MoneyDeposited) { |state, event| state += event.data[:amount] }
          .on(MoneyWithdrawn, MoneyLost) { |state, event| state -= event.data[:amount] }
          .call(event_store.read.in_batches(100))
      expect(balance).to eq(6)
    end

    specify do
      specification = Specification.new(SpecificationReader.new(repository, mapper))
      scope = specification.in_batches(2).of_type([MoneyDeposited, MoneyWithdrawn])
      expect(repository).to receive(:read).with(scope.result).and_return([])

      Projection
        .new(0)
        .on(MoneyDeposited) { |state, event| state += event.data[:amount] }
        .on(MoneyWithdrawn) { |state, event| state -= event.data[:amount] }
        .call(scope)
    end

    specify "default initial state" do
      expect(Projection.new.call([])).to eq(nil)
    end

    specify "block must be given to on event handlers" do
      expect do
        Projection.new.on(MoneyDeposited)
      end.to raise_error(ArgumentError, "No handler block given")
    end

    it "does not support anonymous events" do
      expect do
        Projection.new.on(Class.new) { |_state, _event| }
      end.to raise_error(ArgumentError, "Anonymous class is missing name")
    end

    specify do
      expect(repository).not_to receive(:read)
      state = Projection.new.call(event_store.read)
      expect(state).to eq(nil)
    end

    specify do
      expect(repository).not_to receive(:read)

      initial_state = Object.new
      state = Projection.new(initial_state).call(event_store.read)

      expect(state).to eq(initial_state)
    end
  end
end
