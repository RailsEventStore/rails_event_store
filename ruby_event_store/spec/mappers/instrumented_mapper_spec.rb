require 'spec_helper'
require 'ruby_event_store/spec/dispatcher_lint'
require 'active_support/notifications'

module RubyEventStore
  module Mappers
    RSpec.describe InstrumentedMapper do

      describe "#event_to_serialized_record" do
        specify "wraps around original implementation" do
          domain_event, serialized_record = Object.new, Object.new
          some_mapper = instance_double(RubyEventStore::Mappers::NullMapper)
          allow(some_mapper).to receive(:event_to_serialized_record).with(domain_event).and_return(serialized_record)
          instrumented_mapper = InstrumentedMapper.new(some_mapper, ActiveSupport::Notifications)

          expect(instrumented_mapper.event_to_serialized_record(domain_event)).to eq(serialized_record)
        end

        specify "instruments" do
          instrumented_mapper = InstrumentedMapper.new(spy, ActiveSupport::Notifications)
          subscribe_to("serialize.mapper.rails_event_store") do |notification_calls|
            instrumented_mapper.event_to_serialized_record(domain_event = Object.new)
            expect(notification_calls).to eq([
              { domain_event: domain_event}
            ])
          end
        end
      end

      describe "#serialized_record_to_event" do
        specify "wraps around original implementation" do
          domain_event, serialized_record = Object.new, Object.new
          some_mapper = instance_double(RubyEventStore::Mappers::NullMapper)
          allow(some_mapper).to receive(:serialized_record_to_event).with(serialized_record).and_return(domain_event)
          instrumented_mapper = InstrumentedMapper.new(some_mapper, ActiveSupport::Notifications)

          expect(instrumented_mapper.serialized_record_to_event(serialized_record)).to eq(domain_event)
        end

        specify "instruments" do
          instrumented_mapper = InstrumentedMapper.new(spy, ActiveSupport::Notifications)
          subscribe_to("deserialize.mapper.rails_event_store") do |notification_calls|
            instrumented_mapper.serialized_record_to_event(serialized_record = Object.new)
            expect(notification_calls).to eq([
              { record: serialized_record}
            ])
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
end
