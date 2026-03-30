# frozen_string_literal: true

require "spec_helper"
require "ruby_event_store/spec/mapper_lint"
require "stringio"

module RubyEventStore
  module Mappers
    ::RSpec.describe NullMapper do
      let(:time) { Time.now.utc }
      let(:data) { { some_attribute: 5 } }
      let(:metadata) { { some_meta: 1 } }
      let(:event_id) { SecureRandom.uuid }
      let(:event) do
        TimeEnrichment.with(
          TestEvent.new(data: data, metadata: metadata, event_id: event_id),
          timestamp: time,
          valid_at: time,
        )
      end

      null_mapper_instance =
        begin
          old, $stderr = $stderr, ::StringIO.new
          NullMapper.new
        ensure
          $stderr = old
        end
      it_behaves_like "mapper", null_mapper_instance, TimeEnrichment.with(TestEvent.new)

      specify "warns on initialization" do
        expect { NullMapper.new }.to output(<<~EOS).to_stderr
          DEPRECATION WARNING: `RubyEventStore::Mappers::NullMapper` is deprecated and will be removed in the next major release.
          Use `RubyEventStore::Mappers::Default.new` instead.
        EOS
      end

      specify "#event_to_record" do
        record = subject.event_to_record(event)

        expect(record.event_id).to eq(event.event_id)
        expect(record.data).to eq(event.data)
        expect(record.metadata.to_h).to eq(metadata)
        expect(record.event_type).to eq("TestEvent")
        expect(record.timestamp).to eq(time)
        expect(record.valid_at).to eq(time)
      end

      specify "#record_to_event" do
        record = subject.event_to_record(event)
        event_ = subject.record_to_event(record)

        expect(event_).to eq(event)
        expect(event_.event_id).to eq(event.event_id)
        expect(event_.data).to eq(event.data)
        expect(event_.metadata.to_h).to eq(event.metadata.to_h)
        expect(event_.event_type).to eq("TestEvent")
        expect(event_.metadata[:timestamp]).to eq(time)
        expect(event_.metadata[:valid_at]).to eq(time)
      end
    end
  end
end
