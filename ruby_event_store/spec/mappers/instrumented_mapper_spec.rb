# frozen_string_literal: true

require "spec_helper"
require "active_support/core_ext/object/try"
require "active_support/notifications"

module RubyEventStore
  module Mappers
    ::RSpec.describe InstrumentedMapper do
      let(:event) { instance_double(Event) }
      let(:record) { instance_double(Record) }

      describe "#event_to_record" do
        specify "wraps around original implementation" do
          some_mapper = instance_double(Mappers::Default)
          allow(some_mapper).to receive(:event_to_record).with(event).and_return(record)
          instrumented_mapper = InstrumentedMapper.new(some_mapper, ActiveSupport::Notifications)

          expect(instrumented_mapper.event_to_record(event)).to eq(record)
        end

        specify "instruments" do
          instrumented_mapper = InstrumentedMapper.new(spy, ActiveSupport::Notifications)
          subscribe_to("serialize.mapper.rails_event_store") do |notification_calls|
            instrumented_mapper.event_to_record(event)
            expect(notification_calls).to eq([{ domain_event: event }])
          end
        end
      end

      describe "#record_to_event" do
        specify "wraps around original implementation" do
          some_mapper = instance_double(Mappers::Default)
          allow(some_mapper).to receive(:record_to_event).with(record).and_return(event)
          instrumented_mapper = InstrumentedMapper.new(some_mapper, ActiveSupport::Notifications)

          expect(instrumented_mapper.record_to_event(record)).to eq(event)
        end

        specify "instruments" do
          instrumented_mapper = InstrumentedMapper.new(spy, ActiveSupport::Notifications)
          subscribe_to("deserialize.mapper.rails_event_store") do |notification_calls|
            instrumented_mapper.record_to_event(record)
            expect(notification_calls).to eq([{ record: record }])
          end
        end
      end

      specify "#cleaner_inspect" do
        mapper = Default.new
        instrumented_mapper = InstrumentedMapper.new(mapper, ActiveSupport::Notifications)
        expect(instrumented_mapper.cleaner_inspect).to eq(<<~EOS.chomp)
          #<#{instrumented_mapper.class.name}:0x#{instrumented_mapper.object_id.to_s(16)}>
            - mapper: #{mapper.cleaner_inspect(indent: 2)}
        EOS
      end

      specify "#cleaner_inspect with indent" do
        mapper = Default.new
        instrumented_mapper = InstrumentedMapper.new(mapper, ActiveSupport::Notifications)
        expect(instrumented_mapper.cleaner_inspect(indent: 4)).to eq(<<~EOS.chomp)
          #{' ' * 4}#<#{instrumented_mapper.class.name}:0x#{instrumented_mapper.object_id.to_s(16)}>
          #{' ' * 4}  - mapper: #{mapper.cleaner_inspect(indent: 6)}
        EOS
      end

      def subscribe_to(name)
        received_payloads = []
        callback = ->(_name, _start, _finish, _id, payload) { received_payloads << payload }
        ActiveSupport::Notifications.subscribed(callback, name) { yield received_payloads }
      end
    end
  end
end
