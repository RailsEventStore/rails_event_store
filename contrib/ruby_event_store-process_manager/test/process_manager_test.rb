# frozen_string_literal: true

require_relative "test_helper"

class ProcessManagerTest < Minitest::Test
  cover "RubyEventStore::ProcessManager*"

  class FakeCommandBus
    attr_reader :commands

    def initialize
      @commands = []
    end

    def call(command)
      @commands << command
    end
  end

  class EventStoreWithConcurrentLink
    def initialize(event_store, concurrent_event)
      @event_store = event_store
      @concurrent_event = concurrent_event
    end

    def read
      @event_store.read
    end

    def link(event_id, stream_name:, expected_version:)
      if @concurrent_event
        concurrent_event = @concurrent_event
        @concurrent_event = nil
        @event_store.link(concurrent_event.event_id, stream_name:, expected_version:)
      end

      @event_store.link(event_id, stream_name:, expected_version:)
    end
  end

  OrderPaid = Class.new(RubyEventStore::Event)
  OrderAddressSet = Class.new(RubyEventStore::Event)
  DeliverOrder = Data.define(:order_id)

  OrderDeliveryState = Data.define(:paid, :address_set) do
    def initialize(paid: false, address_set: false)
      super
    end

    def ready_to_deliver?
      paid && address_set
    end
  end

  class OrderDeliveryProcess
    include RubyEventStore::ProcessManager.with_state { OrderDeliveryState }

    subscribes_to OrderPaid, OrderAddressSet

    private

    def fetch_id(event)
      event.data.fetch(:order_id)
    end

    def apply(event)
      case event
      when OrderPaid
        state.with(paid: true)
      when OrderAddressSet
        state.with(address_set: true)
      else
        state
      end
    end

    def act
      command_bus.call(DeliverOrder.new(order_id: id)) if state.ready_to_deliver?
    end
  end

  class ProcessWithCustomToS
    include RubyEventStore::ProcessManager.with_state { OrderDeliveryState }

    def self.to_s = "A different representation"

    private

    def fetch_id(event) = event.data.fetch(:order_id)
    def apply(_event) = state
    def act = nil
  end

  class RegisterableProcess
  end

  class ProcessStreamName
    def to_s = "ProcessManagerTest::OrderDeliveryProcess$1"
  end

  class ProcessConfiguredAtRuntime
  end

  class FrameworkBaseClass
    def initialize
      @constructed_without_dependencies = true
    end
  end

  class AsyncOrderDeliveryProcess < FrameworkBaseClass
    include RubyEventStore::ProcessManager.with_state { OrderDeliveryState }

    subscribes_to OrderPaid, OrderAddressSet

    private

    def fetch_id(event) = event.data.fetch(:order_id)

    def apply(event)
      case event
      when OrderPaid
        state.with(paid: true)
      when OrderAddressSet
        state.with(address_set: true)
      else
        state
      end
    end

    def act
      command_bus.call(DeliverOrder.new(order_id: id)) if state.ready_to_deliver?
    end
  end

  def setup
    @event_store = RubyEventStore::Client.new(repository: RubyEventStore::InMemoryRepository.new)
    @command_bus = FakeCommandBus.new
  end

  def test_issues_command_when_all_conditions_are_met
    process = OrderDeliveryProcess.new.with(event_store: @event_store, command_bus: @command_bus)
    order_id = "order-123"

    paid_event = OrderPaid.new(data: { order_id: })
    @event_store.append(paid_event)
    process.call(paid_event)

    assert_empty(@command_bus.commands)

    address_event = OrderAddressSet.new(data: { order_id: })
    @event_store.append(address_event)
    process.call(address_event)

    assert_equal([DeliverOrder.new(order_id:)], @command_bus.commands)
  end

  def test_works_regardless_of_event_order
    process = OrderDeliveryProcess.new.with(event_store: @event_store, command_bus: @command_bus)
    order_id = "order-456"

    address_event = OrderAddressSet.new(data: { order_id: })
    @event_store.append(address_event)
    process.call(address_event)

    assert_empty(@command_bus.commands)

    paid_event = OrderPaid.new(data: { order_id: })
    @event_store.append(paid_event)
    process.call(paid_event)

    assert_equal([DeliverOrder.new(order_id:)], @command_bus.commands)
  end

  def test_retries_after_another_event_is_linked_concurrently
    order_id = "order-789"
    paid_event = OrderPaid.new(data: { order_id: })
    address_event = OrderAddressSet.new(data: { order_id: })
    @event_store.append(paid_event)
    @event_store.append(address_event)
    concurrent_event_store = EventStoreWithConcurrentLink.new(@event_store, address_event)
    process = OrderDeliveryProcess.new.with(event_store: concurrent_event_store, command_bus: @command_bus)

    process.call(paid_event)

    assert_equal([DeliverOrder.new(order_id:)], @command_bus.commands)
  end

  def test_builds_stream_names_from_the_process_class_name
    process = ProcessWithCustomToS.new.with(event_store: @event_store, command_bus: @command_bus)
    paid_event = OrderPaid.new(data: { order_id: "order-123" })
    @event_store.append(paid_event)

    process.call(paid_event)

    assert_equal([paid_event], @event_store.read.stream("ProcessManagerTest::ProcessWithCustomToS$order-123").to_a)
  end

  def test_subscribes_to_registers_event_classes
    assert_equal([OrderPaid, OrderAddressSet], OrderDeliveryProcess.subscribed_events)
  end

  def test_initializes_subscriptions
    process_class = Class.new

    process_class.extend(RubyEventStore::ProcessManager::Subscriptions)

    assert_empty(process_class.subscribed_events)
  end

  def test_updates_subscriptions
    process_class = Class.new

    process_class.extend(RubyEventStore::ProcessManager::Subscriptions)
    process_class.subscribes_to(OrderPaid, OrderAddressSet)

    assert_equal([OrderPaid, OrderAddressSet], process_class.subscribed_events)
  end

  def test_registers_named_process_managers
    RubyEventStore::ProcessManager.register(RegisterableProcess)

    assert_equal(
      [RegisterableProcess, "1"],
      RubyEventStore::ProcessManager.parse_stream_name("ProcessManagerTest::RegisterableProcess$1"),
    )
  end

  def test_does_not_register_anonymous_process_managers
    assert_nil(RubyEventStore::ProcessManager.register(Class.new))
  end

  def test_coerces_process_stream_names_to_strings
    assert_equal(
      [OrderDeliveryProcess, "1"],
      RubyEventStore::ProcessManager.parse_stream_name(ProcessStreamName.new),
    )
  end

  def test_requires_a_state_class_block
    error = assert_raises(ArgumentError) { RubyEventStore::ProcessManager.with_state }

    assert_equal("A block returning the state class is required.", error.message)
  end

  def test_configures_a_process_class_with_state
    state_module = RubyEventStore::ProcessManager.with_state { OrderDeliveryState }
    ProcessConfiguredAtRuntime.include(state_module)

    process = ProcessConfiguredAtRuntime.new.with(event_store: @event_store, command_bus: @command_bus)

    assert_equal(OrderDeliveryState.new, process.initial_state)
    process.replay([])
    assert_equal(OrderDeliveryState.new, process.state)
    assert_empty(ProcessConfiguredAtRuntime.subscribed_events)
    assert_equal(
      [
        ProcessConfiguredAtRuntime,
        RubyEventStore::ProcessManager::Retry,
        RubyEventStore::ProcessManager::ProcessMethods,
        state_module,
      ],
      ProcessConfiguredAtRuntime.ancestors.take(4),
    )
    assert_equal(
      [ProcessConfiguredAtRuntime, "1"],
      RubyEventStore::ProcessManager.parse_stream_name("ProcessManagerTest::ProcessConfiguredAtRuntime$1"),
    )
  end

  def test_rejects_a_state_definition_that_does_not_return_a_class
    process_class = Class.new
    process_class.include(RubyEventStore::ProcessManager.with_state { Object.new })

    error = assert_raises(RuntimeError) { process_class.new.with(event_store: @event_store, command_bus: @command_bus).initial_state }

    assert_equal("State definition block did not return a Class", error.message)
  end

  def test_reports_a_missing_inherited_state_definition
    process_class = Class.new
    process_class.include(RubyEventStore::ProcessManager.with_state { OrderDeliveryState })
    inherited_process_class = Class.new(process_class)

    error = assert_raises(RuntimeError) { inherited_process_class.new.with(event_store: @event_store, command_bus: @command_bus).initial_state }

    assert_equal("State definition block not found on #{inherited_process_class}", error.message)
  end

  def test_can_be_instantiated_without_arguments_by_a_host_framework_and_configured_afterwards
    process = AsyncOrderDeliveryProcess.new
    assert(process.instance_variable_get(:@constructed_without_dependencies))

    order_id = "order-async-1"
    paid_event = OrderPaid.new(data: { order_id: })
    address_event = OrderAddressSet.new(data: { order_id: })
    @event_store.append(paid_event)
    @event_store.append(address_event)

    process.with(event_store: @event_store, command_bus: @command_bus)
    process.call(paid_event)
    process.call(address_event)

    assert_equal([DeliverOrder.new(order_id:)], @command_bus.commands)
  end

  def test_raises_a_clear_error_upfront_when_call_happens_before_with
    process = OrderDeliveryProcess.new
    paid_event = OrderPaid.new(data: { order_id: "order-1" })

    error = assert_raises(RuntimeError) { process.call(paid_event) }

    assert_equal(
      "ProcessManagerTest::OrderDeliveryProcess is missing event_store and command_bus, " \
        "call #with(event_store:, command_bus:) first",
      error.message,
    )
  end

  def test_raises_a_clear_error_upfront_when_only_the_command_bus_is_missing
    process = OrderDeliveryProcess.new.with(event_store: @event_store, command_bus: nil)
    paid_event = OrderPaid.new(data: { order_id: "order-1" })

    error = assert_raises(RuntimeError) { process.call(paid_event) }

    assert_equal(
      "ProcessManagerTest::OrderDeliveryProcess is missing command_bus, call #with(event_store:, command_bus:) first",
      error.message,
    )
  end
end
