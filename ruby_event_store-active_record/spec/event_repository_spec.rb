# frozen_string_literal: true

require "spec_helper"
require "ruby_event_store"
require "ruby_event_store/spec/event_repository_lint"

module RubyEventStore
  module ActiveRecord
    ::RSpec.describe EventRepository do
      helper = SpecHelper.new
      mk_repository = -> { EventRepository.new(serializer: helper.serializer) }

      it_behaves_like :event_repository, mk_repository, helper

      let(:repository) { mk_repository.call }
      let(:specification) do
        Specification.new(
          SpecificationReader.new(repository, Mappers::Default.new)
        )
      end

      around(:each) { |example| helper.run_lifecycle { example.run } }

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
        repository.append_to_stream(
          [SRecord.new, SRecord.new],
          Stream.new("stream"),
          ExpectedVersion.auto
        )

        expect { repository.read(specification.limit(2).result) }.to match_query_count(1)
        expect { repository.read(specification.limit(2).backward.result) }.to match_query_count(1)
        expect { repository.read(specification.stream("stream").result) }.to match_query_count(2)
        expect { repository.read(specification.stream("stream").backward.result) }.to match_query_count(2)
        expect { repository.read(specification.stream("stream").limit(2).result) }.to match_query_count(2)
        expect { repository.read(specification.stream("stream").limit(2).backward.result) }.to match_query_count(2)
      end

      specify "limited query when looking for non-existing events during linking" do
        expect do
          expect do
            repository.link_to_stream(
              %w[
                72922e65-1b32-4e97-8023-03ae81dd3a27
                d9f6d02a-05f0-4c27-86a9-ad7c4ef73042
              ],
              Stream.new("flow"),
              ExpectedVersion.none
            )
          end.to raise_error(EventNotFound)
        end.to match_query(/SELECT .*event_store_events.*event_id.* FROM .*event_store_events.* WHERE .*event_store_events.*event_id.* IN \(.*, .*\)/)
      end

      specify "use default models" do
        repository = EventRepository.new(serializer: Serializers::YAML)
        expect(repository.instance_variable_get(:@event_klass)).to be(Event)
        expect(repository.instance_variable_get(:@stream_klass)).to be(EventInStream)
      end

      specify "allows custom base class" do
        repository =
          EventRepository.new(
            model_factory: WithAbstractBaseClass.new(CustomApplicationRecord),
            serializer: Serializers::YAML
          )
        expect(repository.instance_variable_get(:@event_klass).ancestors).to include(CustomApplicationRecord)
        expect(repository.instance_variable_get(:@stream_klass).ancestors).to include(CustomApplicationRecord)
      end

      specify "reading/writting works with custom base class" do
        repository =
          EventRepository.new(
            model_factory: WithAbstractBaseClass.new(CustomApplicationRecord),
            serializer: Serializers::YAML
          )
        repository.append_to_stream(
          [event = SRecord.new],
          Stream.new(GLOBAL_STREAM),
          ExpectedVersion.any
        )
        reader = SpecificationReader.new(repository, Mappers::Default.new)
        specification = Specification.new(reader)
        read_event = repository.read(specification.result).first
        expect(read_event).to eq(event)
      end

      specify "timestamps not overwritten by activerecord-import" do
        repository.append_to_stream(
          [event = SRecord.new(timestamp: time = Time.at(0))],
          Stream.new(GLOBAL_STREAM),
          ExpectedVersion.any
        )
        event_ = repository.read(specification.result).first
        expect(event_.timestamp).to eq(time)
      end

      specify "with post-valid-at appended record" do
        Event.create!(
          event_id: id = SecureRandom.uuid,
          data: "{}",
          metadata: "{}",
          event_type: "TestDomainEvent",
          created_at: t1 = with_precision(Time.now.utc),
          valid_at: t2 = with_precision(Time.at(0))
        )
        EventInStream.create!(stream: "stream", position: 1, event_id: id, created_at: t1)

        record = repository.read(specification.result).first
        expect(record.timestamp).to eq(t1)
        expect(record.valid_at).to eq(t2)
      end

      specify "with pre-valid-at appended record" do
        Event.create!(
          event_id: id = SecureRandom.uuid,
          data: "{}",
          metadata: "{}",
          event_type: "TestDomainEvent",
          created_at: t = with_precision(Time.now.utc),
          valid_at: nil
        )
        EventInStream.create!(stream: "stream", position: 1, event_id: id, created_at: t)

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

        event_record = Event.find_by(event_id: record.event_id)
        expect(event_record.created_at).to eq(time)
        expect(event_record.valid_at).to be_nil
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

        event_record = Event.find_by(event_id: record.event_id)
        expect(event_record.created_at).to eq(t1)
        expect(event_record.valid_at).to eq(t2)
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
        }.to match_query(/SELECT.*FROM.*event_store_events.*ORDER BY .*event_store_events.*created_at.* ASC,.*event_store_events.*id.* ASC LIMIT.*.OFFSET.*/)
        expect {
          repository.read(specification.in_batches.as_of.result).to_a
        }.to match_query(/SELECT.*FROM.*event_store_events.*ORDER BY .*COALESCE(.*event_store_events.*valid_at.*, .*event_store_events.*created_at.*).* ASC,.*event_store_events.*id.* ASC LIMIT.*.OFFSET.*/)
      end

      specify "with batches and non-bi-temporal queries use monotonic ids" do
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

        expect do
          expect do
            repository.read(specification.in_batches(3).result).to_a
          end.to match_query(/SELECT.*FROM .event_store_events. ORDER BY .event_store_events.\..id. ASC LIMIT/)
        end.to match_query(/SELECT.*FROM .event_store_events. WHERE .event_store_events\.id >.* ORDER BY .event_store_events.\..id. ASC LIMIT/)
      end

      specify "produces expected query for position in stream call" do
        repository.append_to_stream(
          [event0 = SRecord.new, event1 = SRecord.new],
          stream = Stream.new("stream"),
          ExpectedVersion.auto
        )

        expect {
          repository.position_in_stream(event0.event_id, stream)
        }.to match_query(/SELECT\s+.event_store_events_in_streams.\..position. FROM .event_store_events_in_streams.*/)
      end

      specify "produces expected query for global position call" do
        repository.append_to_stream(
          [event = SRecord.new],
          Stream.new("stream"),
          ExpectedVersion.any
        )
        expect {
          repository.global_position(event.event_id)
        }.to match_query(/SELECT\s+.event_store_events.\..id. FROM .event_store_events.*/)
      end

      specify "don't join events when no event filtering criteria" do
        expect {
          repository.read(specification.stream("stream").result).to_a
        }.to match_query %r{
          SELECT\s+.event_store_events_in_streams.\.\*\s+
          FROM\s+.event_store_events_in_streams.\s+
          WHERE\s+.event_store_events_in_streams.\..stream.\s+=\s+(\?|\$1|'stream')\s+
          ORDER\s+BY\s+.event_store_events_in_streams.\..id.\s+ASC
        }x
      end

      specify 'inner join events when event filtering criteria present' do
        [
          specification.stream("stream").of_type("type"),
          specification.stream("stream").as_of,
          specification.stream("stream").as_at,
          specification.stream("stream").older_than(Time.now),
          specification.stream("stream").older_than_or_equal(Time.now),
          specification.stream("stream").newer_than(Time.now),
          specification.stream("stream").newer_than_or_equal(Time.now),
        ].each do |spec|
          expect {
            repository.read(spec.result).to_a
          }.to match_query(/INNER\s+JOIN\s+.event_store_events./)
        end
      end

      specify "avoid N+1 without additional query when join is used for querying" do
        repository.append_to_stream(
          [SRecord.new, SRecord.new],
          Stream.new("stream"),
          ExpectedVersion.auto
        )
        expect { repository.read(specification.stream("stream").of_type("type").result) }.to match_query_count(1)
        expect { repository.read(specification.stream("stream").as_of.result) }.to match_query_count(1)
        expect { repository.read(specification.stream("stream").as_at.result) }.to match_query_count(1)
        expect { repository.read(specification.stream("stream").older_than(Time.now).result) }.to match_query_count(1)
        expect { repository.read(specification.stream("stream").older_than_or_equal(Time.now).result) }.to match_query_count(1)
        expect { repository.read(specification.stream("stream").newer_than(Time.now).result) }.to match_query_count(1)
        expect { repository.read(specification.stream("stream").newer_than_or_equal(Time.now).result) }.to match_query_count(1)
      end

      specify "don't join events when no event filtering criteria when counting" do
        expect {
          repository.count(specification.stream("stream").result)
        }.to match_query %r{
          SELECT\s+COUNT\(\*\)\s+
          FROM\s+.event_store_events_in_streams.\s+
          WHERE\s+.event_store_events_in_streams.\..stream.\s+=\s+(\?|\$1|'stream')
        }x
      end

      private

      def with_precision(time)
        time.round(TIMESTAMP_PRECISION)
      end
    end
  end
end
