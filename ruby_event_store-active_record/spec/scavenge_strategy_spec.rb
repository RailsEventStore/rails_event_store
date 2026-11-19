# frozen_string_literal: true

require "spec_helper"
require "ruby_event_store"
require "ruby_event_store/spec/scavenge_strategy_lint"

module RubyEventStore
  module ActiveRecord
    ::RSpec.describe ScavengeStrategy do
      helper = NativeTruncationSpecHelper.new
      serializer = ENV["DATA_TYPE"].start_with?("json") ? JSON : Serializers::YAML
      mk_repository = -> { EventRepository.new(serializer: serializer) }

      around { |example| helper.run_lifecycle { example.run } }

      it_behaves_like "scavenge strategy", mk_repository, -> { ScavengeStrategy.new }

      let(:repository) { mk_repository.call }
      let(:strategy) { ScavengeStrategy.new }
      let(:stream) { Stream.new("Order$1") }
      let(:far_future) { Time.now.utc + 365 * 24 * 3600 }
      let(:long_ago) { Time.utc(2000, 1, 1) }
      let(:column) { /[`"]?\w+[`"]?\.[`"]?%s[`"]?/.source }

      def append(count, expected_version = ExpectedVersion.auto)
        records = Array.new(count) { SRecord.new }
        repository.append_to_stream(records, stream, expected_version)
        records.map(&:event_id)
      end

      def write(type, **data)
        repository.append_stream_metadata(
          SRecord.new(
            event_type: "RubyEventStore::StreamMetadataEvents::#{type}",
            data: { "stream" => stream.name }.merge(data.transform_keys(&:to_s)),
          ),
          stream,
          ExpectedVersion.any,
        )
      end

      def plan(now: Time.now.utc)
        strategy.plan(stream, now: now, sweep_before: far_future)
      end

      def read
        repository.read(Specification.new(nil).stream(stream.name).result).map(&:event_id)
      end

      def truncated_at
        EventInStream.where(stream: stream.name).order(:id).pluck(:truncated_at)
      end

      def after_ids_selected(&block)
        allow_any_instance_of(::ActiveRecord::Relation).to receive(:pluck).and_wrap_original do |original, *columns|
          original.call(*columns).tap { block.call if original.receiver.limit_value.eql?(10) }
        end
      end

      specify "lists streams ordered by name in SQL" do
        expect { strategy.streams(after: nil, limit: 2) }.to match_query(/ORDER BY #{column % "stream"} ASC/)
      end

      specify "selects entries to mark oldest first, then marks them by id" do
        append(3)
        write("StreamMetadataChanged", max_count: 1, max_age: nil)
        plan = plan()

        expect { strategy.mark(plan, 10, now: Time.now.utc) }.to match_query(
          /ORDER BY #{column % "id"} ASC/,
        ).and match_query(/\AUPDATE (?!.*SELECT)/m)
      end

      specify "selects entries to sweep oldest first, then deletes them by id" do
        append(3)
        write("StreamSoftDeleted")
        repository.mark_truncated(stream, 10)

        expect { strategy.sweep(stream, 10, before: far_future) }.to match_query(
          /ORDER BY #{column % "id"} ASC/,
        ).and match_query(/\ADELETE (?!.*SELECT)/m)
      end

      specify "leaves an entry marked after it was selected" do
        append(3)
        write("StreamMetadataChanged", max_count: 1, max_age: nil)
        plan = plan()
        after_ids_selected { EventInStream.where(stream: stream.name).update_all(truncated_at: long_ago) }

        expect(strategy.mark(plan, 10, now: Time.now.utc)).to eq(0)
        expect(truncated_at).to eq([long_ago] * 3)
      end

      specify "leaves an entry shown again after it was selected" do
        append(3)
        write("StreamSoftDeleted")
        repository.mark_truncated(stream, 10)
        after_ids_selected { EventInStream.where(stream: stream.name).update_all(truncated_at: nil) }

        expect(strategy.sweep(stream, 10, before: far_future)).to eq(0)
        expect(truncated_at).to eq([nil] * 3)
      end

      specify "keeps the entry with the highest position as the anchor when a newer one has none" do
        event_ids = append(3)
        append(1, ExpectedVersion.any)
        write("StreamSoftDeleted")
        repository.mark_truncated(stream, 10)

        expect(strategy.sweep(stream, 10, before: far_future)).to eq(3)

        write("StreamRestored")
        repository.unmark_truncated(stream, 10)
        expect(read).to eq(event_ids.last(1))
      end

      specify "works on the tables of the model factory" do
        model_factory = WithAbstractBaseClass.new(CustomApplicationRecord)
        repository = EventRepository.new(serializer: serializer, model_factory: model_factory)
        repository.append_to_stream([SRecord.new, SRecord.new], stream, ExpectedVersion.auto)
        repository.append_stream_metadata(
          SRecord.new(
            event_type: "RubyEventStore::StreamMetadataEvents::StreamMetadataChanged",
            data: {
              "stream" => stream.name,
              "max_count" => 1,
              "max_age" => nil,
            },
          ),
          stream,
          ExpectedVersion.any,
        )
        strategy = ScavengeStrategy.new(model_factory: model_factory)

        expect(strategy.streams(after: nil, limit: 10)).to eq([stream])
        expect(strategy.plan(stream, now: Time.now.utc, sweep_before: far_future).to_mark).to eq(1)
      end
    end
  end
end
