require "spec_helper"
require "active_support"
require "active_support/core_ext/time"

module RubyEventStore
  module Mappers
    ::RSpec.describe PreserveTypesMapper do

      specify "preserves type of ActiveSupport::TimeWithZone" do
        time_zone = Time.zone
        Time.zone = "Europe/Warsaw"

        record = subject.event_to_record(TestEvent.new(
          data: { active_support_time_with_zone: Time.zone.local(2021, 8, 5, 12, 0, 0) })
        )

        expect(record.metadata[:types])
          .to eq({
                   :data => { :active_support_time_with_zone => ["Symbol", "ActiveSupport::TimeWithZone"] },
                   :metadata => {}
                 })
      ensure
        Time.zone = time_zone
      end

      specify "preserves type of Time" do
        record = subject.event_to_record(TestEvent.new(data: { time: Time.new(2021, 8, 5, 12, 0, 0) }))

        expect(record.metadata[:types]).to eq({ :data => { :time => ["Symbol", "Time"] }, :metadata => {} })
      end

      specify "preserves type of UTC Time" do
        record = subject.event_to_record(TestEvent.new(data: { time: Time.new(2021, 8, 5, 12, 0, 0).utc }))

        expect(record.metadata[:types]).to eq({ :data => { :time => ["Symbol", "Time"] }, :metadata => {} })
      end

      specify "preserves type of DateTime" do
        record = subject.event_to_record(TestEvent.new(data: { datetime: DateTime.new(2021, 8, 5, 12, 0, 0) }))

        expect(record.metadata[:types]).to eq({ :data => { :datetime => ["Symbol", "DateTime"] }, :metadata => {} })
      end

      specify "preserves type of Date" do
        record = subject.event_to_record(TestEvent.new(data: { date: Date.new(2021, 8, 5, 12) }))

        expect(record.metadata[:types]).to eq({ :data => { :date => ["Symbol", "Date"] }, :metadata => {} })
      end

      specify "preserves type of metadata keys" do
        record = subject.event_to_record(TestEvent.new(data: {}, metadata: { "hashhash": "test" }))

        expect(record.metadata[:types]).to eq({ data: {}, metadata: { hashhash: ["Symbol", "String"] } })
      end

      specify "symbolizes metadata keys" do
        record = subject.event_to_record(TestEvent.new(data: {}, metadata: { "hashhash": "test" }))

        expect(record.metadata)
          .to eq({ :hashhash => "test", types: { data: {}, metadata: { hashhash: ["Symbol", "String"] } } })
      end

      specify "reads type of ActiveSupport::TimeWithZone" do
        time_zone = Time.zone
        Time.zone = "Europe/Warsaw"

        event = TestEvent.new(data: { active_support_time_with_zone: Time.zone.local(2021, 8, 5, 12, 0, 0) })
        expect(subject.record_to_event(subject.event_to_record(event))).to eq(event)
      ensure
        Time.zone = time_zone
      end

      specify "reads type of Time" do
        event = TestEvent.new(data: { time: Time.new(2021, 8, 5, 12, 0, 0) })
        expect(subject.record_to_event(subject.event_to_record(event))).to eq(event)
      end

      specify "reads type of UTC Time" do
        event = TestEvent.new(data: { time: Time.new(2021, 8, 5, 12, 0, 0).utc })

        expect(subject.record_to_event(subject.event_to_record(event))).to eq(event)
      end

      specify "reads type of DateTime" do
        event = TestEvent.new(data: { datetime: DateTime.new(2021, 8, 5, 12, 0, 0) })

        expect(subject.record_to_event(subject.event_to_record(event))).to eq(event)
      end

      specify "reads type of Date" do
        event = TestEvent.new(data: { date: Date.new(2021, 8, 5, 12) })

        expect(subject.record_to_event(subject.event_to_record(event))).to eq(event)
      end

      specify "reads type of metadata keys" do
        event = TestEvent.new(data: {}, metadata: { "hashhash": "test" })

        expect(subject.record_to_event(subject.event_to_record(event))).to eq(event)
      end
    end
  end
end