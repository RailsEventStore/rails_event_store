# frozen_string_literal: true

require "spec_helper"
require "active_support"
require "active_support/notifications"

module AggregateRoot
  ::RSpec.describe InstrumentedApplyStrategy do
    describe "#call" do
      specify "wraps around original implementation" do
        strategy = instance_double(DefaultApplyStrategy)
        instrumented_strategy = InstrumentedApplyStrategy.new(strategy, ActiveSupport::Notifications)
        aggregate = Object.new
        event = Object.new

        expect(strategy).to receive(:call).with(aggregate, event)
        instrumented_strategy.call(aggregate, event)
      end

      specify "instruments" do
        strategy = instance_double(DefaultApplyStrategy)
        instrumented_strategy = InstrumentedApplyStrategy.new(strategy, ActiveSupport::Notifications)
        subscribe_to("apply.aggregate_root") do |notification_calls|
          aggregate = Object.new
          event = Object.new

          expect(strategy).to receive(:call).with(aggregate, event)
          instrumented_strategy.call(aggregate, event)

          expect(notification_calls).to eq([{ aggregate: aggregate, event: event }])
        end
      end
    end

    specify "method unknown by instrumentation but known by strategy" do
      some_strategy = double("Some strategy", custom_method: 42)
      instrumented_strategy = InstrumentedApplyStrategy.new(some_strategy, ActiveSupport::Notifications)
      block = -> { "block" }
      instrumented_strategy.custom_method("arg", keyword: "keyarg", &block)

      expect(instrumented_strategy).to respond_to(:custom_method)
      expect(some_strategy).to have_received(:custom_method).with("arg", keyword: "keyarg") do |&received_block|
        expect(received_block).to be(block)
      end
    end

    specify "method unknown by instrumentation and unknown by strategy" do
      some_strategy = instance_double(DefaultApplyStrategy)
      instrumented_strategy = InstrumentedApplyStrategy.new(some_strategy, ActiveSupport::Notifications)

      expect(instrumented_strategy).not_to respond_to(:arbitrary_method_name)
      expect do instrumented_strategy.arbitrary_method_name end.to raise_error(
        NoMethodError,
        /undefined method.+arbitrary_method_name/,
      )
    end

    def subscribe_to(name)
      received_payloads = []
      callback = ->(_name, _start, _finish, _id, payload) { received_payloads << payload }
      ActiveSupport::Notifications.subscribed(callback, name) { yield received_payloads }
    end
  end
end
