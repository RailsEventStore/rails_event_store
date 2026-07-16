# frozen_string_literal: true

require "spec_helper"

module RubyEventStore
  module ActiveRecord
    ::RSpec.describe StreamPrefixPattern do
      describe ".for" do
        it "picks Glob for sqlite" do
          expect(StreamPrefixPattern.for(fake_stream_klass("SQLite"))).to be_a(StreamPrefixPattern::Glob)
        end

        it "picks Like for mysql" do
          expect(StreamPrefixPattern.for(fake_stream_klass("Mysql2"))).to be_a(StreamPrefixPattern::Like)
        end

        it "picks CollateC for postgres with the stream COLLATE \"C\" index present" do
          expect(StreamPrefixPattern.for(fake_stream_klass("PostgreSQL", index_lookup_value: true))).to be_a(
            StreamPrefixPattern::CollateC,
          )
        end

        it "picks nothing for postgres without the stream COLLATE \"C\" index" do
          expect(StreamPrefixPattern.for(fake_stream_klass("PostgreSQL", index_lookup_value: nil))).to be_nil
        end

        it "looks the index up by the stream klass table name" do
          stream_klass = fake_stream_klass("PostgreSQL", index_lookup_value: nil)

          StreamPrefixPattern.for(stream_klass)

          expect(stream_klass.connection).to have_received(:select_value).with(
            a_string_matching(/'event_store_events_in_streams'/).and(a_string_matching(/'stream'/)),
            "SCHEMA",
          )
        end

        def fake_stream_klass(adapter_name, index_lookup_value: nil)
          connection = double(adapter_name: adapter_name)
          allow(connection).to receive(:select_value).and_return(index_lookup_value)
          allow(connection).to receive(:quote) { |value| "'#{value}'" }
          double(connection: connection, table_name: "event_store_events_in_streams")
        end
      end

      describe StreamPrefixPattern::Like do
        subject(:pattern) { StreamPrefixPattern::Like.new }

        specify do
          expect(pattern.condition).to eq("stream LIKE ?")
        end

        specify do
          expect(pattern.bind_value("Stream")).to eq("Stream%")
        end

        specify "escapes LIKE metacharacters in the prefix" do
          expect(pattern.bind_value("50%off")).to eq('50\%off%')
          expect(pattern.bind_value("a_b")).to eq('a\_b%')
        end

        specify do
          expect(pattern.cursor_condition).to eq("stream > ?")
        end

        specify do
          expect(pattern.order).to eq(:stream)
        end
      end

      describe StreamPrefixPattern::CollateC do
        subject(:pattern) { StreamPrefixPattern::CollateC.new }

        specify do
          expect(pattern.condition).to eq('stream COLLATE "C" LIKE ?')
        end

        specify do
          expect(pattern.bind_value("Stream")).to eq("Stream%")
        end

        specify "escapes LIKE metacharacters in the prefix" do
          expect(pattern.bind_value("50%off")).to eq('50\%off%')
        end

        specify do
          expect(pattern.cursor_condition).to eq('stream COLLATE "C" > ?')
        end

        specify "orders byte-wise to match the index" do
          expect(pattern.order).to eq(Arel.sql('stream COLLATE "C" ASC'))
          expect(pattern.order).to be_a(Arel::Nodes::SqlLiteral)
        end
      end

      describe StreamPrefixPattern::Glob do
        subject(:pattern) { StreamPrefixPattern::Glob.new }

        specify do
          expect(pattern.condition).to eq("stream GLOB ?")
        end

        specify do
          expect(pattern.bind_value("Stream")).to eq("Stream*")
        end

        specify "escapes GLOB metacharacters in the prefix" do
          expect(pattern.bind_value("a*b?c[d")).to eq("a[*]b[?]c[[]d*")
        end

        specify do
          expect(pattern.cursor_condition).to eq("stream > ?")
        end

        specify do
          expect(pattern.order).to eq(:stream)
        end
      end
    end
  end
end
