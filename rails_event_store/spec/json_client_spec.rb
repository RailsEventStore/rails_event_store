# frozen_string_literal: true

require "spec_helper"
require "active_support"
require "active_support/core_ext/time"
require "json"
require "ostruct"

module RailsEventStore
  ::RSpec.describe JSONClient do
    let(:client) do
      JSONClient.new(repository: RubyEventStore::InMemoryRepository.new(serializer: JSON))
    end

    specify "reads type of ActiveSupport::TimeWithZone" do
      time_zone = Time.zone
      Time.zone = "Europe/Warsaw"

      event =
        DummyEvent.new(
          data: {
            active_support_time_with_zone: with_precision(Time.zone.local(2021, 8, 5, 12, 0, 0.1)),
          },
        )
      client.append(event)

      event_ = client.read.event(event.event_id)
      expect(event_).to eq(event)
      expect(event_.data[:active_support_time_with_zone]).to be_a(ActiveSupport::TimeWithZone)
    ensure
      Time.zone = time_zone
    end

    specify "reads type of BigDecimal" do
      event = DummyEvent.new(data: { money: BigDecimal("123.45") })
      client.append(event)

      expect(client.read.event(event.event_id)).to eq(event)
    end

    specify "reads type of Time" do
      event = DummyEvent.new(data: { time: with_precision(Time.new(2021, 8, 5, 12, 0, 0.1)) })
      client.append(event)

      expect(client.read.event(event.event_id)).to eq(event)
    end

    specify "reads type of UTC Time" do
      event = DummyEvent.new(data: { time: with_precision(Time.new(2021, 8, 5, 12, 0, 0.1).utc) })
      client.append(event)

      expect(client.read.event(event.event_id)).to eq(event)
    end

    specify "reads type of DateTime" do
      event = DummyEvent.new(data: { datetime: DateTime.new(2021, 8, 5, 12, 0, 0) })
      client.append(event)

      expect(client.read.event(event.event_id)).to eq(event)
    end

    specify "reads type of Date" do
      event = DummyEvent.new(data: { date: Date.new(2021, 8, 5, 12) })
      client.append(event)

      expect(client.read.event(event.event_id)).to eq(event)
    end

    specify "reads type of metadata keys" do
      event = DummyEvent.new(data: {}, metadata: { hashhash: "test" })
      client.append(event)

      expect(client.read.event(event.event_id)).to eq(event)
    end

    specify "reads type of OpenStruct" do
      event = DummyEvent.new(data: OpenStruct.new(a: 1))
      client.append(event)

      expect(client.read.event(event.event_id)).to eq(event)
    end

    private

    def with_precision(time)
      time.round(RubyEventStore::TIMESTAMP_PRECISION)
    end
  end
end
