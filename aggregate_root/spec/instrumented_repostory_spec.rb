require 'spec_helper'
require 'active_support/notifications'

module AggregateRoot
  RSpec.describe InstrumentedRepository do

    describe "#load" do
      specify "wraps around original implementation" do
        repository = instance_double(Repository)
        instrumented_repository = InstrumentedRepository.new(repository, ActiveSupport::Notifications)
        aggregate = Order.new

        expect(repository).to receive(:load).with(aggregate, 'SomeStream')
        instrumented_repository.load(aggregate, 'SomeStream')
      end

      specify "instruments" do
        repository = instance_double(Repository)
        instrumented_repository = InstrumentedRepository.new(repository, ActiveSupport::Notifications)
        subscribe_to("load.repository.aggregate_root") do |notification_calls|
          aggregate = Order.new

          expect(repository).to receive(:load).with(aggregate, 'SomeStream')
          instrumented_repository.load(aggregate, 'SomeStream')

          expect(notification_calls).to eq([{
            aggregate: aggregate,
            stream: 'SomeStream',
          }])
        end
      end
    end

    describe "#store" do
      specify "wraps around original implementation" do
        repository = instance_double(Repository)
        instrumented_repository = InstrumentedRepository.new(repository, ActiveSupport::Notifications)
        aggregate = Order.new

        expect(repository).to receive(:store).with(aggregate, 'SomeStream')
        instrumented_repository.store(aggregate, 'SomeStream')
      end

      specify "instruments" do
        repository = instance_double(Repository)
        instrumented_repository = InstrumentedRepository.new(repository, ActiveSupport::Notifications)
        subscribe_to("store.repository.aggregate_root") do |notification_calls|
          aggregate = Order.new
          aggregate.create
          aggregate.expire
          events = aggregate.unpublished_events.to_a

          expect(repository).to receive(:store).with(aggregate, 'SomeStream')
          instrumented_repository.store(aggregate, 'SomeStream')

          expect(notification_calls).to eq([{
            aggregate: aggregate,
            version: -1,
            stored_events: events,
            stream: 'SomeStream',
          }])
        end
      end
    end

    describe "#with_aggregate" do
      specify "wraps around original implementation" do
        repository = instance_double(Repository)
        instrumented_repository = InstrumentedRepository.new(repository, ActiveSupport::Notifications)
        aggregate = Order.new
        specific_block = Proc.new { }

        expect(repository).to receive(:with_aggregate).with(aggregate, 'SomeStream') do |&block|
          expect(block).to be(specific_block)
        end
        instrumented_repository.with_aggregate(aggregate, 'SomeStream', &specific_block)
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
