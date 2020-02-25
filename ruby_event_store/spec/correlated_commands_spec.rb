require 'spec_helper'
require 'time'

module RubyEventStore
  RSpec.describe CorrelatedCommands do

    module CorrelableCommand
      attr_accessor :correlation_id, :causation_id

      def correlate_with(other_message)
        self.correlation_id = other_message.correlation_id || other_message.message_id
        self.causation_id   = other_message.message_id
      end
    end

    class AddProductCommand
      include CorrelableCommand

      attr_accessor :message_id, :product_id

      def initialize(product_id:, message_id: SecureRandom.uuid)
        self.product_id = product_id
        self.message_id = message_id
      end
    end

    class TestCommand
      include CorrelableCommand

      attr_accessor :message_id

      def initialize(message_id: SecureRandom.uuid)
        self.message_id = message_id
      end
    end

    let(:event_store) do
      RubyEventStore::Client.new(repository: InMemoryRepository.new)
    end
    let(:command_bus) do
      -> (cmd) do
        {
          AddProductCommand => -> (c) do
            event_store.publish(ProductAdded.new(data:{
              product_id: c.product_id,
            }))
          end,
          TestCommand => -> (_c) do
            event_store.publish(TestEvent.new())
          end,
        }.fetch(cmd.class).call(cmd)
      end
    end

    specify "correlate produced events with current command" do
      bus = CorrelatedCommands.new(event_store, command_bus)
      bus.call(cmd = TestCommand.new)
      event = event_store.read.first
      expect(event.correlation_id).to eq(cmd.message_id)
      expect(event.causation_id).to eq(cmd.message_id)
      expect(cmd.message_id).to be_a(String)
    end

    specify "correlate commands with events from sync handlers" do
      cmd2 = nil
      bus = CorrelatedCommands.new(event_store, command_bus)
      event_store.subscribe(to: [ProductAdded]) do
        bus.call(cmd2 = TestCommand.new)
      end
      bus.call(cmd1 = AddProductCommand.new(product_id: 20))

      expect(cmd1.correlation_id).to be_nil
      expect(cmd1.causation_id).to be_nil

      event1 = event_store.read.first
      expect(event1.correlation_id).to eq(cmd1.message_id)
      expect(event1.causation_id).to eq(cmd1.message_id)

      expect(cmd2.correlation_id).to eq(cmd1.message_id)
      expect(cmd2.causation_id).to eq(event1.message_id)

      event2 = event_store.read.last
      expect(event2.correlation_id).to eq(cmd1.message_id)
      expect(event2.causation_id).to eq(cmd2.message_id)
    end

    specify "correlate commands with events from sync handlers (missing correlate_with)" do
      cmd2 = TestCommand.new
      cmd2.instance_eval('undef :correlate_with')

      cmd1 = AddProductCommand.new(product_id: 20)
      cmd1.instance_eval('undef :correlate_with')

      bus = CorrelatedCommands.new(event_store, command_bus)
      event_store.subscribe(to: [ProductAdded]) do
        bus.call(cmd2)
      end
      bus.call(cmd1)

      expect(cmd1.correlation_id).to be_nil
      expect(cmd1.causation_id).to be_nil

      event1 = event_store.read.first
      expect(event1.correlation_id).to eq(cmd1.message_id)
      expect(event1.causation_id).to eq(cmd1.message_id)

      expect(cmd2.correlation_id).to be_nil
      expect(cmd2.causation_id).to be_nil

      event2 = event_store.read.last
      expect(event2.correlation_id).to eq(cmd1.message_id)
      expect(event2.causation_id).to eq(cmd2.message_id)
    end

    specify "both correlation_id and causation_id must be set to correlate command" do
      event_store.with_metadata(correlation_id: "COID") do
        bus = CorrelatedCommands.new(event_store, command_bus)
        bus.call(cmd = TestCommand.new)
        expect(cmd.correlation_id).to be_nil
        expect(cmd.causation_id).to be_nil
      end

      event_store.with_metadata(causation_id: "CAID") do
        bus = CorrelatedCommands.new(event_store, command_bus)
        bus.call(cmd = TestCommand.new)
        expect(cmd.correlation_id).to be_nil
        expect(cmd.causation_id).to be_nil
      end
    end

  end
end
