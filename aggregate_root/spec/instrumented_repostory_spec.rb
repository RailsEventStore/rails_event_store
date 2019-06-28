# frozen_string_literal: true

require 'spec_helper'
require 'active_support/notifications'

module AggregateRoot
  RSpec.describe InstrumentedRepository do
    describe "#load" do
      specify "wraps around original implementation" do
        repository = instance_double(Repository)
        instrumented_repository = InstrumentedRepository.new(repository, ActiveSupport::Notifications)
        aggregate = Order.new(SecureRandom.uuid)

        expect(repository).to receive(:load).with(aggregate, 'SomeStream')
        instrumented_repository.load(aggregate, 'SomeStream')
      end

      specify "instruments" do
        repository = instance_double(Repository)
        instrumented_repository = InstrumentedRepository.new(repository, ActiveSupport::Notifications)
        subscribe_to("load.repository.aggregate_root") do |notification_calls|
          aggregate = Order.new(SecureRandom.uuid)

          expect(repository).to receive(:load).with(aggregate, 'SomeStream')
          instrumented_repository.load(aggregate, 'SomeStream')

          expect(notification_calls).to eq(
            [{
              aggregate: aggregate,
              stream:    'SomeStream',
            }]
          )
        end
      end
    end

    describe "#store" do
      specify "wraps around original implementation" do
        repository = instance_double(Repository)
        instrumented_repository = InstrumentedRepository.new(repository, ActiveSupport::Notifications)
        aggregate = Order.new(SecureRandom.uuid)

        expect(repository).to receive(:store).with(aggregate, 'SomeStream')
        instrumented_repository.store(aggregate, 'SomeStream')
      end

      specify "instruments" do
        repository = instance_double(Repository)
        instrumented_repository = InstrumentedRepository.new(repository, ActiveSupport::Notifications)
        subscribe_to("store.repository.aggregate_root") do |notification_calls|
          aggregate = Order.new(SecureRandom.uuid)
          aggregate.create
          aggregate.expire
          events = aggregate.unpublished_events.to_a

          expect(repository).to receive(:store).with(aggregate, 'SomeStream')
          instrumented_repository.store(aggregate, 'SomeStream')

          expect(notification_calls).to eq(
            [{
              aggregate:     aggregate,
              version:       -1,
              stored_events: events,
              stream:        'SomeStream',
            }]
          )
        end
      end
    end

    describe "#with_aggregate" do
      specify "instruments both load and store" do
        repository = instance_double(Repository)
        instrumented_repository = InstrumentedRepository.new(repository, ActiveSupport::Notifications)
        subscribe_to("load.repository.aggregate_root") do |load_notification_calls|
          aggregate = Order.new(SecureRandom.uuid)

          subscribe_to("store.repository.aggregate_root") do |store_notification_calls|
            events = nil

            expect(repository).to receive(:load).with(aggregate, 'SomeStream')
            expect(repository).to receive(:store).with(aggregate, 'SomeStream')
            instrumented_repository.with_aggregate(aggregate, 'SomeStream') do
              aggregate.create
              aggregate.expire
              events = aggregate.unpublished_events.to_a
            end

            expect(store_notification_calls).to eq(
              [{
                aggregate:     aggregate,
                version:       -1,
                stored_events: events,
                stream:        'SomeStream',
              }]
            )
          end

          expect(load_notification_calls).to eq(
            [{
              aggregate: aggregate,
              stream:    'SomeStream',
            }]
          )
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
