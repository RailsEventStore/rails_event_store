# frozen_string_literal: true

require_relative "test_helper"
require "ruby_event_store/process_manager/state_replay"

class StateReplayTest < Minitest::Test
  cover "RubyEventStore::ProcessManager*"

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

  def setup
    @event_store = RubyEventStore::Client.new(repository: RubyEventStore::InMemoryRepository.new)
    @command_bus = ->(_command) {}
  end

  def test_parse_stream_name_recognizes_process_manager_streams_by_naming_convention
    assert_equal(
      [ReplayOrderProcess, "order-1"],
      RubyEventStore::ProcessManager.parse_stream_name("StateReplayTest::ReplayOrderProcess$order-1"),
    )
  end

  def test_parse_stream_name_returns_nil_for_streams_without_the_separator
    assert_nil(RubyEventStore::ProcessManager.parse_stream_name("orders"))
  end

  def test_parse_stream_name_returns_nil_when_the_id_part_is_empty
    assert_nil(RubyEventStore::ProcessManager.parse_stream_name("StateReplayTest::ReplayOrderProcess$"))
  end

  def test_parse_stream_name_returns_nil_for_names_not_registered_as_process_managers
    assert_nil(RubyEventStore::ProcessManager.parse_stream_name("NoSuchProcess$1"))
    assert_nil(RubyEventStore::ProcessManager.parse_stream_name("String$1"))
    assert_nil(RubyEventStore::ProcessManager.parse_stream_name("foo bar$1"))
  end

  def test_parse_stream_name_does_not_recognize_classes_that_skip_with_state
    hand_rolled_process = Class.new do
      include RubyEventStore::ProcessManager::ProcessMethods
    end
    self.class.const_set(:HandRolledProcess, hand_rolled_process)

    assert_nil(RubyEventStore::ProcessManager.parse_stream_name("StateReplayTest::HandRolledProcess$1"))
  ensure
    self.class.send(:remove_const, :HandRolledProcess) if self.class.const_defined?(:HandRolledProcess, false)
  end

  def test_replay_returns_successive_states_without_acting
    process = ReplayOrderProcess.new.with(event_store: @event_store, command_bus: @command_bus)
    paid = ReplayOrderPaid.new(data: { order_id: "order-1" })
    address = ReplayOrderAddressSet.new(data: { order_id: "order-1" })

    assert_equal(
      [ReplayOrderState.new(paid: true), ReplayOrderState.new(paid: true, address_set: true)],
      process.replay([paid, address]),
    )
  end

  def test_replay_starts_from_the_initial_state_on_every_invocation
    process = ReplayOrderProcess.new.with(event_store: @event_store, command_bus: @command_bus)
    paid = ReplayOrderPaid.new(data: { order_id: "order-1" })

    process.replay([paid])

    assert_empty(process.replay([]))
    assert_equal([ReplayOrderState.new(paid: true)], process.replay([paid]))
  end

  def test_call_rebuilds_state_step_by_step_from_the_process_stream
    process = ReplayOrderProcess.new.with(event_store: @event_store, command_bus: @command_bus)
    paid = ReplayOrderPaid.new(data: { order_id: "order-1" })
    address = ReplayOrderAddressSet.new(data: { order_id: "order-1" })
    @event_store.append(paid)
    process.call(paid)
    @event_store.append(address)
    process.call(address)

    replay =
      RubyEventStore::ProcessManager::StateReplay.new(event_store: @event_store).call(
        ReplayOrderProcess,
        "StateReplayTest::ReplayOrderProcess$order-1",
      )

    assert_equal([paid.event_id, address.event_id], replay.steps.map(&:event).map(&:event_id))
    assert_equal(
      [ReplayOrderState.new(paid: true), ReplayOrderState.new(paid: true, address_set: true)],
      replay.steps.map(&:state),
    )
    assert_equal(ReplayOrderState.new(paid: true, address_set: true), replay.current_state)
  end

  def test_call_returns_no_steps_and_the_initial_state_for_an_empty_stream
    replay =
      RubyEventStore::ProcessManager::StateReplay.new(event_store: @event_store).call(
        ReplayOrderProcess,
        "StateReplayTest::ReplayOrderProcess$order-2",
      )

    assert_empty(replay.steps)
    assert_equal(ReplayOrderState.new, replay.current_state)
  end
end
