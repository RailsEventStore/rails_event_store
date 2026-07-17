# frozen_string_literal: true

require "spec_helper"
require "ruby_event_store/process_manager/state_replay"

RSpec.describe RubyEventStore::ProcessManager::StateReplay do
  let(:event_store) { RubyEventStore::Client.new(repository: RubyEventStore::InMemoryRepository.new) }
  let(:command_bus) { ->(command) {} }

  ReplayOrderPaid = Class.new(RubyEventStore::Event)
  ReplayOrderAddressSet = Class.new(RubyEventStore::Event)

  ReplayOrderState = Data.define(:paid, :address_set) do
    def initialize(paid: false, address_set: false)
      super
    end

    def ready_to_deliver?
      paid && address_set
    end
  end

  class ReplayOrderProcess
    include RubyEventStore::ProcessManager.with_state { ReplayOrderState }

    subscribes_to ReplayOrderPaid, ReplayOrderAddressSet

    private

    def fetch_id(event)
      event.data.fetch(:order_id)
    end

    def apply(event)
      case event
      when ReplayOrderPaid
        state.with(paid: true)
      when ReplayOrderAddressSet
        state.with(address_set: true)
      else
        state
      end
    end

    def act
    end
  end

  describe ".parse_stream_name" do
    specify "recognizes process manager streams by naming convention" do
      expect(RubyEventStore::ProcessManager.parse_stream_name("ReplayOrderProcess$order-1")).to eq(
        [ReplayOrderProcess, "order-1"],
      )
    end

    specify "returns nil for streams without the separator" do
      expect(RubyEventStore::ProcessManager.parse_stream_name("orders")).to be_nil
    end

    specify "returns nil when the id part is empty" do
      expect(RubyEventStore::ProcessManager.parse_stream_name("ReplayOrderProcess$")).to be_nil
    end

    specify "returns nil for names not registered as process managers" do
      expect(RubyEventStore::ProcessManager.parse_stream_name("NoSuchProcess$1")).to be_nil
      expect(RubyEventStore::ProcessManager.parse_stream_name("String$1")).to be_nil
      expect(RubyEventStore::ProcessManager.parse_stream_name("foo bar$1")).to be_nil
    end

    specify "does not recognize classes that skip with_state" do
      class HandRolledProcess
        include RubyEventStore::ProcessManager::ProcessMethods
      end

      expect(RubyEventStore::ProcessManager.parse_stream_name("HandRolledProcess$1")).to be_nil
    end
  end

  describe "ProcessMethods#replay" do
    specify "returns successive states without acting" do
      process = ReplayOrderProcess.new(event_store, command_bus)
      paid = ReplayOrderPaid.new(data: { order_id: "order-1" })
      address = ReplayOrderAddressSet.new(data: { order_id: "order-1" })

      expect(process.replay([paid, address])).to eq(
        [ReplayOrderState.new(paid: true), ReplayOrderState.new(paid: true, address_set: true)],
      )
    end

    specify "starts from the initial state on every invocation" do
      process = ReplayOrderProcess.new(event_store, command_bus)
      paid = ReplayOrderPaid.new(data: { order_id: "order-1" })

      process.replay([paid])
      expect(process.replay([])).to eq([])
      expect(process.replay([paid])).to eq([ReplayOrderState.new(paid: true)])
    end
  end

  describe "#call" do
    specify "rebuilds state step by step from the process stream" do
      process = ReplayOrderProcess.new(event_store, command_bus)
      paid = ReplayOrderPaid.new(data: { order_id: "order-1" })
      address = ReplayOrderAddressSet.new(data: { order_id: "order-1" })
      event_store.append(paid)
      process.call(paid)
      event_store.append(address)
      process.call(address)

      replay = described_class.new(event_store: event_store).call(ReplayOrderProcess, "ReplayOrderProcess$order-1")

      expect(replay.steps.map(&:event).map(&:event_id)).to eq([paid.event_id, address.event_id])
      expect(replay.steps.map(&:state)).to eq(
        [ReplayOrderState.new(paid: true), ReplayOrderState.new(paid: true, address_set: true)],
      )
      expect(replay.current_state).to eq(ReplayOrderState.new(paid: true, address_set: true))
    end

    specify "returns no steps and the initial state for an empty stream" do
      replay = described_class.new(event_store: event_store).call(ReplayOrderProcess, "ReplayOrderProcess$order-2")

      expect(replay.steps).to eq([])
      expect(replay.current_state).to eq(ReplayOrderState.new)
    end
  end
end
