# frozen_string_literal: true

require "spec_helper"
require "active_support/core_ext/object/try"
require "active_support/isolated_execution_state"
require "active_support/notifications"

module RubyEventStore
  module Mappers
    ::RSpec.describe InstrumentedBatchMapper do
      let(:events) { 3.times.map { instance_double(Event) } }
      let(:records) { 3.times.map { instance_double(Record) } }

      describe "#events_to_records" do
        specify "wraps around original implementation" do
          some_mapper = instance_double(Mappers::BatchMapper)
          allow(some_mapper).to receive(:events_to_records).with(events).and_return(records)
          instrumented_mapper = InstrumentedBatchMapper.new(some_mapper, ActiveSupport::Notifications)

          expect(instrumented_mapper.events_to_records(events)).to eq(records)
        end

        specify "instruments" do
          instrumented_mapper = InstrumentedBatchMapper.new(spy, ActiveSupport::Notifications)
          subscribe_to("events_to_records.mapper.ruby_event_store") do |notification_calls|
            instrumented_mapper.events_to_records(events)
            expect(notification_calls).to eq([{ domain_events: events }])
          end
        end

        specify "instruments with legacy event name" do
          some_mapper = spy
          instrumented_mapper = InstrumentedBatchMapper.new(some_mapper, ActiveSupport::Notifications)
          subscribe_to("events_to_records.mapper.rails_event_store") do |notification_calls|
            instrumented_mapper.events_to_records(events)
            expect(notification_calls).to eq([{ domain_events: events }])
            expect(some_mapper).to have_received(:events_to_records).with(events)
          end
        end

        specify "warns about deprecated event names" do
          instrumented_mapper = InstrumentedBatchMapper.new(spy, ActiveSupport::Notifications)
          subscribe_to("events_to_records.mapper.rails_event_store") do |_|
            expect { instrumented_mapper.events_to_records(events) }.to output(
              /Instrumentation event names \*\.rails_event_store are deprecated/
            ).to_stderr
          end
        end

        specify "does not warn when nobody subscribes to legacy event name" do
          instrumented_mapper = InstrumentedBatchMapper.new(spy, ActiveSupport::Notifications)
          expect { instrumented_mapper.events_to_records(events) }.not_to output(
            /Instrumentation event names \*\.rails_event_store are deprecated/
          ).to_stderr
        end

        specify "does not warn when subscriber also matches new event name" do
          instrumented_mapper = InstrumentedBatchMapper.new(spy, ActiveSupport::Notifications)
          subscribe_to(/event_store/) do |_|
            expect { instrumented_mapper.events_to_records(events) }.not_to output(
              /Instrumentation event names \*\.rails_event_store are deprecated/
            ).to_stderr
          end
        end
      end

      describe "#records_to_events" do
        specify "wraps around original implementation" do
          some_mapper = instance_double(Mappers::BatchMapper)
          allow(some_mapper).to receive(:records_to_events).with(records).and_return(events)
          instrumented_mapper = InstrumentedBatchMapper.new(some_mapper, ActiveSupport::Notifications)

          expect(instrumented_mapper.records_to_events(records)).to eq(events)
        end

        specify "instruments" do
          instrumented_mapper = InstrumentedBatchMapper.new(spy, ActiveSupport::Notifications)
          subscribe_to("records_to_events.mapper.ruby_event_store") do |notification_calls|
            instrumented_mapper.records_to_events(records)
            expect(notification_calls).to eq([{ records: records }])
          end
        end

        specify "instruments with legacy event name" do
          instrumented_mapper = InstrumentedBatchMapper.new(spy, ActiveSupport::Notifications)
          subscribe_to("records_to_events.mapper.rails_event_store") do |notification_calls|
            instrumented_mapper.records_to_events(records)
            expect(notification_calls).to eq([{ records: records }])
          end
        end

        specify "warns about deprecated event names" do
          instrumented_mapper = InstrumentedBatchMapper.new(spy, ActiveSupport::Notifications)
          subscribe_to("records_to_events.mapper.rails_event_store") do |_|
            expect { instrumented_mapper.records_to_events(records) }.to output(
              /Instrumentation event names \*\.rails_event_store are deprecated/
            ).to_stderr
          end
        end
      end

      def subscribe_to(name)
        received_payloads = []
        callback = ->(_name, _start, _finish, _id, payload) { received_payloads << payload }
        ActiveSupport::Notifications.subscribed(callback, name) { yield received_payloads }
      end
    end
  end
end
