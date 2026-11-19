# frozen_string_literal: true

require "spec_helper"
require "ruby_event_store"
require "ruby_event_store/spec/event_repository_lint"

module RubyEventStore
  module ActiveRecord
    ::RSpec.describe "native truncation performance" do
      helper = NativeTruncationSpecHelper.new

      around { |example| helper.run_lifecycle { example.run } }

      def new_repository = EventRepository.new(serializer: ENV["DATA_TYPE"].start_with?("json") ? JSON : Serializers::YAML)

      let(:repository) { new_repository }
      let(:specification) { Specification.new(SpecificationReader.new(repository, Mappers::Default.new)) }
      let(:stream) { Stream.new("Order$1") }
      let(:connection) { ::ActiveRecord::Base.connection }
      let(:visible_index) { "index_event_store_events_in_streams_on_stream_and_id_visible" }

      def metadata_record(type, **data)
        SRecord.new(
          event_type: "RubyEventStore::StreamMetadataEvents::#{type}",
          data: { "stream" => stream.name }.merge(data.transform_keys(&:to_s)),
        )
      end

      def read_sql(repository, spec)
        repository.send(:repo_reader).send(:read_scope, spec.result).to_sql
      end

      def without_truncated_at
        NativeTruncationSpecHelper.new.tap do |helper|
          helper.remove_truncated_at
          helper.reset_column_information
        end
      end

      def q(name) = connection.quote_table_name(name)

      def queries
        sqls = []
        ActiveSupport::Notifications.subscribed(
          ->(*, payload) { sqls << payload[:sql] unless %w[CACHE SCHEMA].include?(payload[:name]) },
          /^sql\./,
        ) { yield }
        sqls
      end

      specify ":auto append to a stream with metadata costs as many queries as to one without" do
        other = Stream.new("Order$2")
        repository.append_to_stream([SRecord.new], stream, ExpectedVersion.auto)
        repository.append_to_stream([SRecord.new], other, ExpectedVersion.auto)
        repository.append_stream_metadata(metadata_record(:StreamMetadataChanged, max_count: 10, max_age: nil), stream, ExpectedVersion.any)

        plain = queries { repository.append_to_stream([SRecord.new], other, ExpectedVersion.auto) }
        with_metadata =
          queries do
            position, tombstoned = repository.last_stream_version_and_tombstone(stream)
            expect(tombstoned).to be(false)
            repository.append_to_stream([SRecord.new], stream, ExpectedVersion.new(position))
          end

        expect(with_metadata.size).to eq(plain.size)
        expect(repository.position_in_stream(repository.last_stream_event(stream).event_id, stream)).to eq(1)
      end

      specify "stream read with truncated_at costs as many queries as without" do
        repository.append_to_stream([SRecord.new, SRecord.new], stream, ExpectedVersion.auto)
        read = ->(repository) do
          queries { repository.read(specification.stream(stream.name).result).to_a }.size
        end

        with_column = read.(repository)
        without_truncated_at

        expect(with_column).to eq(2)
        expect(read.(new_repository)).to eq(with_column)
      end

      specify "SQL without truncated_at migration stays as it was" do
        without_truncated_at
        repository = new_repository
        specification = Specification.new(SpecificationReader.new(repository, Mappers::Default.new))
        table = "event_store_events_in_streams"

        expect(read_sql(repository, specification.stream(stream.name).limit(10))).to eq(
          "SELECT #{q(table)}.* FROM #{q(table)} WHERE #{q(table)}.#{q("stream")} = 'Order$1' " \
            "ORDER BY #{q(table)}.#{q("id")} ASC LIMIT 10",
        )

        event = SRecord.new
        executed =
          queries do
            repository.append_to_stream([event], stream, ExpectedVersion.auto)
            repository.read(specification.stream(stream.name).result).to_a
            repository.read(specification.stream(stream.name).from(event.event_id).result).to_a
            repository.count(specification.stream(stream.name).result)
            repository.last_stream_event(stream)
            repository.position_in_stream(event.event_id, stream)
            repository.event_in_stream?(event.event_id, stream)
            repository.streams_of(event.event_id)
          end
        expect(executed.grep(/truncated_at/)).to be_empty
        expect(repository.supports_native_truncation?).to be(false)
      end

      specify "SQL with truncated_at migration skips hidden entries" do
        table = "event_store_events_in_streams"

        expect(read_sql(repository, specification.stream(stream.name).limit(10))).to eq(
          "SELECT #{q(table)}.* FROM #{q(table)} WHERE #{q(table)}.#{q("stream")} = 'Order$1' " \
            "AND #{q(table)}.#{q("truncated_at")} IS NULL ORDER BY #{q(table)}.#{q("id")} ASC LIMIT 10",
        )
      end

      specify "global stream read is not filtered" do
        expect(read_sql(repository, specification.limit(10))).not_to include("truncated_at")
      end

      specify "stream read hits the partial index on PostgreSQL" do
        skip unless ENV["DATABASE_URL"].include?("postgres")

        repository.append_to_stream([SRecord.new, SRecord.new], stream, ExpectedVersion.auto)
        [specification.stream(stream.name), specification.stream(stream.name).backward.limit(1)].each do |spec|
          plan =
            connection.transaction do
              connection.execute("SET LOCAL enable_seqscan = off")
              connection.select_values("EXPLAIN #{read_sql(repository, spec)}").join("\n")
            end

          expect(plan).to include(visible_index)
        end
      end

      specify "stream read hits the partial index on SQLite" do
        skip unless ENV["DATABASE_URL"].include?("sqlite")

        repository.append_to_stream([SRecord.new, SRecord.new], stream, ExpectedVersion.auto)
        plan = connection.select_rows("EXPLAIN QUERY PLAN #{read_sql(repository, specification.stream(stream.name))}")

        expect(plan.flatten.join("\n")).to include(visible_index)
      end
    end
  end
end
