require "spec_helper"
require "active_support"
require "active_support/core_ext/time"
require "json"

module RubyEventStore
  module Mappers
    ::RSpec.describe PreserveTypesMapper do
      let(:client) do
        RubyEventStore::Client.new(
          mapper: PreserveTypesMapper.new,
          repository: RubyEventStore::InMemoryRepository.new(serializer: JSON)
        )
      end

      specify "preserves Symbol" do
        record = subject.event_to_record(TestEvent.new(data: { foo: :bar }))

        expect(record.metadata[:types]).to eq({ data: { foo: %w[Symbol Symbol] }, metadata: {} })
        expect(record.data).to eq({ "foo" => "bar" })
      end

      specify "preserves type of ActiveSupport::TimeWithZone" do
        time_zone = Time.zone
        Time.zone = "Europe/Warsaw"

        record =
          subject.event_to_record(
            TestEvent.new(data: { active_support_time_with_zone: Time.zone.local(2021, 8, 5, 12, 0, 0) })
          )

        expect(record.metadata[:types]).to eq(
          { data: { active_support_time_with_zone: %w[Symbol ActiveSupport::TimeWithZone] }, metadata: {} }
        )
      ensure
        Time.zone = time_zone
      end

      specify "preserves type of Time" do
        record = subject.event_to_record(TestEvent.new(data: { time: Time.new(2021, 8, 5, 12, 0, 0) }))

        expect(record.metadata[:types]).to eq({ data: { time: %w[Symbol Time] }, metadata: {} })
      end

      specify "preserves type of UTC Time" do
        record = subject.event_to_record(TestEvent.new(data: { time: Time.new(2021, 8, 5, 12, 0, 0).utc }))

        expect(record.metadata[:types]).to eq({ data: { time: %w[Symbol Time] }, metadata: {} })
      end

      specify "preserves type of DateTime" do
        record = subject.event_to_record(TestEvent.new(data: { datetime: DateTime.new(2021, 8, 5, 12, 0, 0) }))

        expect(record.metadata[:types]).to eq({ data: { datetime: %w[Symbol DateTime] }, metadata: {} })
      end

      specify "preserves type of Date" do
        record = subject.event_to_record(TestEvent.new(data: { date: Date.new(2021, 8, 5, 12) }))

        expect(record.metadata[:types]).to eq({ data: { date: %w[Symbol Date] }, metadata: {} })
      end

      specify "preserves type of metadata keys" do
        record = subject.event_to_record(TestEvent.new(data: {}, metadata: { hashhash: "test" }))

        expect(record.metadata[:types]).to eq({ data: {}, metadata: { hashhash: %w[Symbol String] } })
      end

      specify "symbolizes metadata keys" do
        record = subject.event_to_record(TestEvent.new(data: {}, metadata: { hashhash: "test" }))

        expect(record.metadata).to eq(
          { hashhash: "test", types: { data: {}, metadata: { hashhash: %w[Symbol String] } } }
        )
      end

      specify "reads type of ActiveSupport::TimeWithZone" do
        time_zone = Time.zone
        Time.zone = "Europe/Warsaw"

        event =
          TestEvent.new(
            data: {
              active_support_time_with_zone: with_precision(Time.zone.local(2021, 8, 5, 12, 0, 0.1))
            }
          )
        client.append(event)

        event_ = client.read.event(event.event_id)
        expect(event_).to eq(event)
        expect(event_.data[:active_support_time_with_zone]).to be_a(ActiveSupport::TimeWithZone)
      ensure
        Time.zone = time_zone
      end

      specify "reads type of Time" do
        event = TestEvent.new(data: { time: with_precision(Time.new(2021, 8, 5, 12, 0, 0.1)) })
        client.append(event)

        expect(client.read.event(event.event_id)).to eq(event)
      end

      specify "reads type of UTC Time" do
        event = TestEvent.new(data: { time: with_precision(Time.new(2021, 8, 5, 12, 0, 0.1).utc) })
        client.append(event)

        expect(client.read.event(event.event_id)).to eq(event)
      end

      specify "reads type of DateTime" do
        event = TestEvent.new(data: { datetime: DateTime.new(2021, 8, 5, 12, 0, 0) })
        client.append(event)

        expect(client.read.event(event.event_id)).to eq(event)
      end

      specify "reads type of Date" do
        event = TestEvent.new(data: { date: Date.new(2021, 8, 5, 12) })
        client.append(event)

        expect(client.read.event(event.event_id)).to eq(event)
      end

      specify "reads type of metadata keys" do
        event = TestEvent.new(data: {}, metadata: { hashhash: "test" })
        client.append(event)

        expect(client.read.event(event.event_id)).to eq(event)
      end

      private

      def with_precision(time)
        time.round(RubyEventStore::TIMESTAMP_PRECISION)
      end
    end
  end
end
