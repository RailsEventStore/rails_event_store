require 'spec_helper'
require 'active_support/notifications'

module AggregateRoot
  RSpec.describe InstrumentedRepository do

    describe "#load" do
      specify "wraps around original implementation" do
        some_repository = spy
        instrumented_repository = InstrumentedRepository.new(some_repository, ActiveSupport::Notifications)
        aggregate = Order.new

        instrumented_repository.load(aggregate, 'SomeStream')

        expect(some_repository).to have_received(:load).with(aggregate, 'SomeStream')
      end

      specify "instruments" do
        instrumented_repository = InstrumentedRepository.new(spy, ActiveSupport::Notifications)
        subscribe_to("load.repository.aggregate_root") do |notification_calls|
          aggregate = Order.new

          instrumented_repository.load(aggregate, 'SomeStream')

          expect(notification_calls).to eq([{
            aggregate_class: Order,
            stream_name: 'SomeStream',
          }])
        end
      end
    end

    describe "#store" do
      specify "wraps around original implementation" do
        some_repository = spy
        instrumented_repository = InstrumentedRepository.new(some_repository, ActiveSupport::Notifications)
        aggregate = Order.new

        instrumented_repository.store(aggregate, 'SomeStream')

        expect(some_repository).to have_received(:store).with(aggregate, 'SomeStream')
      end

      specify "instruments" do
        instrumented_repository = InstrumentedRepository.new(spy, ActiveSupport::Notifications)
        subscribe_to("store.repository.aggregate_root") do |notification_calls|
          aggregate = Order.new
          aggregate.create
          aggregate.expire

          instrumented_repository.store(aggregate, 'SomeStream')

          expect(notification_calls).to eq([{
            aggregate_class: Order,
            aggregate_version: -1,
            stored_events: 2,
            stream_name: 'SomeStream',
          }])
        end
      end
    end

    describe "#with_aggregate" do
      specify "wraps around original implementation" do
        some_repository = spy
        instrumented_repository = InstrumentedRepository.new(some_repository, ActiveSupport::Notifications)
        aggregate = Order.new
        specific_block = Proc.new { }

        instrumented_repository.with_aggregate(aggregate, 'SomeStream', &specific_block)

        expect(some_repository).to have_received(:with_aggregate).with(aggregate, 'SomeStream') do |&block|
          expect(block).to be(specific_block)
        end
      end
    end

    def subscribe_to(name)
      received_payloads = []
      callback = ->(_name, _start, _finish, _id, payload) { received_payloads << payload }
      ActiveSupport::Notifications.subscribed(callback, name) do
        yield received_payloads
      end
    end
  end
end
