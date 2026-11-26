# frozen_string_literal: true

require "spec_helper"

module RubyEventStore
  module ActiveRecord
    ::RSpec.describe "native truncation migrations" do
      helper = NativeTruncationSpecHelper.new

      around { |example| helper.run_lifecycle { example.run } }

      let(:connection) { ::ActiveRecord::Base.connection }
      let(:visible_index) { "index_event_store_events_in_streams_on_stream_and_id_visible" }
      let(:stream_and_id_index) { "index_event_store_events_in_streams_on_stream_and_id" }

      specify "adds truncated_at column" do
        column = connection.columns("event_store_events_in_streams").find { |c| c.name == "truncated_at" }

        expect(column.null).to be(true)
        expect(column.type).to eq(:datetime)
        expect(column.default).to be_nil
      end

      specify "replaces stream and id index with partial one, except on MySQL" do
        indexes = connection.indexes("event_store_events_in_streams").to_h { |i| [i.name, i] }

        if ENV["DATABASE_URL"].include?("mysql")
          expect(indexes.keys).to include(stream_and_id_index)
          expect(indexes.keys).not_to include(visible_index)
        else
          expect(indexes.keys).not_to include(stream_and_id_index)
          expect(indexes.fetch(visible_index).columns).to eq(%w[stream id])
          expect(indexes.fetch(visible_index).where).to match(/truncated_at IS NULL/i)
        end
      end

      specify "reverts to the stream and id index" do
        helper.remove_truncated_at

        indexes = connection.indexes("event_store_events_in_streams").map(&:name)
        expect(indexes).to include(stream_and_id_index)
        expect(indexes).not_to include(visible_index)
        expect(connection.column_exists?("event_store_events_in_streams", :truncated_at)).to be(false)
      end

      specify "can be run again after an interruption" do
        expect { helper.add_truncated_at }.not_to raise_error
      end

      specify "creates streams metadata table" do
        columns = connection.columns("event_store_streams_metadata").to_h { |c| [c.name, c] }

        expect(columns.keys).to eq(
          %w[id stream max_count max_age truncate_before truncated_upto_id soft_deleted_at tombstoned_at],
        )
        expect(columns.except("id", "stream").values.map(&:null)).to all(be(true))
        expect(columns.fetch("stream").null).to be(false)
        expect(connection.indexes("event_store_streams_metadata").map { |i| [i.columns, i.unique] }).to eq(
          [[%w[stream], true]],
        )
      end
    end
  end
end
