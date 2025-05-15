# frozen_string_literal: true

require "spec_helper"

module RubyEventStore
  module Mappers
    module Transformation
      ::RSpec.describe DomainEvent do
        
        let(:uuid) { SecureRandom.uuid }
        let(:time) { Time.now.utc }
        let(:event) do
          TimeEnrichment.with(
            TestEvent.new(event_id: uuid, data: { some: "value" }, metadata: { some: "meta" }),
            timestamp: time,
            valid_at: time
          )
        end
        let(:record) do
          Record.new(
            event_id: uuid,
            metadata: {
              some: "meta"
            },
            data: {
              some: "value"
            },
            event_type: "TestEvent",
            timestamp: time,
            valid_at: time
          )
        end

        specify "#dump" do
          expect(DomainEvent.new.dump(event)).to eq(record)
        end

        specify "#load" do
          loaded = DomainEvent.new.load(record)
          expect(loaded).to eq(event)
          expect(loaded.metadata.to_h).to eq(event.metadata.to_h)
        end

        specify "does not mutate custom event" do
          event_klass =
            Class.new do
              def initialize(data, metadata)
                @event_id = SecureRandom.uuid
                @data = data
                @metadata = metadata
              end

              attr_reader :event_id, :data, :metadata

              def event_type
                "bazinga"
              end
            end

          DomainEvent.new.dump(
            event = event_klass.new({ some: "data" }, { some: "meta", valid_at: time, timestamp: time })
          )

          expect(event.data).to eq({ some: "data" })
          expect(event.metadata).to eq({ some: "meta", valid_at: time, timestamp: time })
        end

        specify "loading an event without its class" do
          record_ = Record.new(**record.to_h, event_type: "NoneSuch")
          loaded = DomainEvent.new.load(record_)
          expect(loaded).to be_a(Event)
          expect(loaded.event_type).to eq("NoneSuch")
          expect(loaded.event_id).to eq(event.event_id)
          expect(loaded.data).to eq(event.data)
          expect(loaded.metadata.to_h).to eq(event.metadata.to_h.merge(event_type: "NoneSuch"))
        end
      end
    end
  end
end
