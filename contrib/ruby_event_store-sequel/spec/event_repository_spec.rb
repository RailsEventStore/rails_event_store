# frozen_string_literal: true

require "spec_helper"
require "ruby_event_store/spec/event_repository_lint"

module RubyEventStore
  module Sequel
    ::RSpec.describe EventRepository do
      helper = SpecHelper.new
      mk_repository = -> { EventRepository.new(sequel: helper.sequel, serializer: helper.serializer) }

      it_behaves_like :event_repository, mk_repository, helper

      around(:each) { |example| helper.run_lifecycle { example.run } }

      let(:repository) { mk_repository.call }
      let(:specification) { Specification.new(SpecificationReader.new(repository, Mappers::Default.new)) }

      specify "nested transaction - events still not persisted if append failed" do
        repository.append_to_stream(
          [event = SRecord.new(event_id: SecureRandom.uuid)],
          Stream.new("stream"),
          ExpectedVersion.none
        )

        helper.with_transaction do
          expect do
            repository.append_to_stream(
              [SRecord.new(event_id: "9bedf448-e4d0-41a3-a8cd-f94aec7aa763")],
              Stream.new("stream"),
              ExpectedVersion.none
            )
          end.to raise_error(WrongExpectedEventVersion)
          expect(repository.has_event?("9bedf448-e4d0-41a3-a8cd-f94aec7aa763")).to be false
          expect(repository.read(specification.limit(2).result).to_a).to eq([event])
        end
        expect(repository.has_event?("9bedf448-e4d0-41a3-a8cd-f94aec7aa763")).to be false
        expect(repository.read(specification.limit(2).result).to_a).to eq([event])
      end

      specify "avoid N+1" do
        repository.append_to_stream([SRecord.new, SRecord.new], Stream.new("stream"), ExpectedVersion.auto)

        expect { repository.read(specification.limit(2).result) }.to match_query_count(1)
        expect { repository.read(specification.limit(2).backward.result) }.to match_query_count(1)
        expect { repository.read(specification.stream("stream").result) }.to match_query_count(1)
        expect { repository.read(specification.stream("stream").backward.result) }.to match_query_count(1)
        expect { repository.read(specification.stream("stream").limit(2).result) }.to match_query_count(1)
        expect { repository.read(specification.stream("stream").limit(2).backward.result) }.to match_query_count(1)
      end

      specify "limited query when looking for non-existing events during linking" do
        expect do
          expect do
            repository.link_to_stream(
              %w[72922e65-1b32-4e97-8023-03ae81dd3a27 d9f6d02a-05f0-4c27-86a9-ad7c4ef73042],
              Stream.new("flow"),
              ExpectedVersion.none
            )
          end.to raise_error(EventNotFound)
        end.to match_query(/SELECT .*event_store_events.*event_id.* FROM .*event_store_events.* WHERE .*event_store_events.*.event_id.* IN \('72922e65-1b32-4e97-8023-03ae81dd3a27', 'd9f6d02a-05f0-4c27-86a9-ad7c4ef73042'\).*/)
      end

      specify "with post-valid-at appended record" do
        helper.sequel[:event_store_events].insert(
          event_id: id = SecureRandom.uuid,
          data: "{}",
          metadata: "{}",
          event_type: "TestDomainEvent",
          created_at: t1 = with_precision(Time.now.utc),
          valid_at: t2 = with_precision(Time.at(0))
        )

        helper.sequel[:event_store_events_in_streams].insert(
          stream: "stream",
          position: 1,
          event_id: id,
          created_at: t1
        )

        record = repository.read(specification.result).first
        expect(record.timestamp).to eq(t1)
        expect(record.valid_at).to eq(t2)
      end

      specify "with pre-valid-at appended record" do
        helper.sequel[:event_store_events].insert(
          event_id: id = SecureRandom.uuid,
          data: "{}",
          metadata: "{}",
          event_type: "TestDomainEvent",
          created_at: t = with_precision(Time.now.utc),
          valid_at: nil
        )

        record = repository.read(specification.result).first
        expect(record.timestamp).to eq(t)
        expect(record.valid_at).to eq(t)
      end

      specify "valid-at storage optimization when same as created-at" do
        repository.append_to_stream(
          [SRecord.new(timestamp: time = with_precision(Time.at(0)))],
          Stream.new(GLOBAL_STREAM),
          ExpectedVersion.any
        )
        record = repository.read(specification.result).first
        expect(record.timestamp).to eq(time)
        expect(record.valid_at).to eq(time)

        event_record = helper.sequel[:event_store_events].where(event_id: record.event_id).first
        expect(event_record[:created_at]).to eq(time)
        expect(event_record[:valid_at]).to be_nil
      end

      specify "no valid-at storage optimization when different from created-at" do
        repository.append_to_stream(
          [
            SRecord.new(
              timestamp: t1 = with_precision(Time.at(0)),
              valid_at: t2 = with_precision(Time.at(1))
            )
          ],
          Stream.new(GLOBAL_STREAM),
          ExpectedVersion.any
        )
        record = repository.read(specification.result).first
        expect(record.timestamp).to eq(t1)
        expect(record.valid_at).to eq(t2)

        event_record = helper.sequel[:event_store_events].where(event_id: record.event_id).first
        expect(event_record[:created_at]).to eq(t1)
        expect(event_record[:valid_at]).to eq(t2)
      end

      specify do
        repository.append_to_stream(
          [event0 = SRecord.new, event1 = SRecord.new],
          stream = Stream.new("stream"),
          ExpectedVersion.auto
        )

        expect {
          repository.position_in_stream(event0.event_id, stream)
        }.to match_query(/SELECT\s+.event_store_events_in_streams.\..position. FROM .event_store_events_in_streams.*/)
      end

      specify do
        repository.append_to_stream(
          [event = SRecord.new],
          Stream.new("stream"),
          ExpectedVersion.any
        )
        expect {
          repository.global_position(event.event_id)
        }.to match_query(/SELECT\s+.event_store_events.\..id. FROM .event_store_events.*/)
      end


      specify "with batches and bi-temporal queries use offset + limit" do
        repository.append_to_stream(
          [
            SRecord.new(
              event_id: e1 = SecureRandom.uuid,
              timestamp: Time.new(2020, 1, 1),
              valid_at: Time.new(2020, 1, 9)
            ),
            SRecord.new(
              event_id: e2 = SecureRandom.uuid,
              timestamp: Time.new(2020, 1, 3),
              valid_at: Time.new(2020, 1, 6)
            ),
            SRecord.new(
              event_id: e3 = SecureRandom.uuid,
              timestamp: Time.new(2020, 1, 2),
              valid_at: Time.new(2020, 1, 3)
            )
          ],
          Stream.new("Dummy"),
          ExpectedVersion.any
        )

        expect {
          repository.read(specification.in_batches.as_at.result).to_a
        }.to match_query(/SELECT\s+(.*)\s+FROM\s+.event_store_events.\s+ORDER\s+BY\s+.event_store_events.\..created_at.\s+LIMIT.\d+\sOFFSET.\d+/)
        expect {
          repository.read(specification.in_batches.as_of.result).to_a
        }.to match_query(/SELECT.*FROM .*event_store_events.* ORDER BY COALESCE.*event_store_events.*valid_at.*event_store_events.*created_at.*LIMIT \d+ OFFSET \d+/)
      end

      private

      def with_precision(time)
        time.round(TIMESTAMP_PRECISION)
      end
    end
  end
end
