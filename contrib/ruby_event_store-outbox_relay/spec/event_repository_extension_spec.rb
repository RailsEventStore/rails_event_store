# frozen_string_literal: true

require "spec_helper"

module RubyEventStore
  module OutboxRelay
    ::RSpec.describe EventRepositoryExtension do
      helper = SpecHelper.new
      event_klass = RubyEventStore::ActiveRecord::WithDefaultModels.new.call.first

      around { |example| helper.run_lifecycle { example.run } }

      let(:repository) { RubyEventStore::ActiveRecord::EventRepository.new(serializer: helper.serializer) }

      def build_record(event)
        now = Time.now.utc
        RubyEventStore::Record.new(
          event_id: event.event_id,
          data: event.data,
          metadata: event.metadata,
          event_type: event.event_type,
          timestamp: now,
          valid_at: now,
        )
      end

      specify "is prepended onto RubyEventStore::ActiveRecord::EventRepository" do
        expect(RubyEventStore::ActiveRecord::EventRepository.ancestors.first).to eq(EventRepositoryExtension)
      end

      specify "exposes the configured serializer publicly" do
        expect(repository.serializer).to equal(helper.serializer)
      end

      specify "writes published_at as nil in the same insert, by default" do
        record = build_record(TestEvent.new)

        repository.append_to_stream([record], Stream.new(GLOBAL_STREAM), ExpectedVersion.any)

        row = event_klass.find_by!(event_id: record.event_id)
        expect(row.published_at).to be_nil
      end

      specify "writes published_at as already set inside WithoutRelay.call" do
        record = build_record(TestEvent.new)

        WithoutRelay.call { repository.append_to_stream([record], Stream.new(GLOBAL_STREAM), ExpectedVersion.any) }

        expect(event_klass.find_by!(event_id: record.event_id).published_at).not_to be_nil
      end

      specify "the published_at it assigns inside WithoutRelay.call is in UTC" do
        record = build_record(TestEvent.new)
        serialized_record = record.serialize(repository.serializer)

        hash = WithoutRelay.call { repository.send(:insert_hash, record, serialized_record) }

        expect(hash[:published_at]).to be_utc
      end

      specify "every event written through this repository is affected, not just the first" do
        first = build_record(TestEvent.new)
        repository.append_to_stream([first], Stream.new(GLOBAL_STREAM), ExpectedVersion.any)

        second = build_record(TestEvent.new)
        repository.append_to_stream([second], Stream.new(GLOBAL_STREAM), ExpectedVersion.any)

        expect(event_klass.find_by!(event_id: first.event_id).published_at).to be_nil
        expect(event_klass.find_by!(event_id: second.event_id).published_at).to be_nil
      end
    end
  end
end
