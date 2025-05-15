# frozen_string_literal: true

require "spec_helper"

module RubyEventStore
  module Transformations
    ::RSpec.describe WithIndifferentAccess do
      def record(hash, time)
        RubyEventStore::Record.new(
          event_id: "not-important",
          data: hash,
          metadata: hash,
          event_type: "does-not-matter",
          timestamp: time,
          valid_at: time
        )
      end

      specify "#load" do
        time = Time.now
        hash = { simple: "data", array: [1, 2, 3, { some: "hash" }], hash: { nested: { any: "value" }, meh: 3 } }
        result = WithIndifferentAccess.new.load(record(hash, time))

        expect(result.data).to be_a(ActiveSupport::HashWithIndifferentAccess)
        expect(result.metadata).to be_a(ActiveSupport::HashWithIndifferentAccess)
        expect(result.data[:array].last).to be_a(ActiveSupport::HashWithIndifferentAccess)
        expect(result.data[:hash]).to be_a(ActiveSupport::HashWithIndifferentAccess)
        expect(result.data[:hash][:nested]).to be_a(ActiveSupport::HashWithIndifferentAccess)

        [result.data, result.metadata].each do |d|
          expect(d[:simple]).to eq("data")
          expect(d[:array].first).to eq(1)
          expect(d[:array].last[:some]).to eq("hash")
          expect(d[:hash][:meh]).to eq(3)
          expect(d[:hash][:nested][:any]).to eq("value")
          expect(d["simple"]).to eq("data")
          expect(d["array"].first).to eq(1)
          expect(d["array"].last["some"]).to eq("hash")
          expect(d["hash"]["meh"]).to eq(3)
          expect(d["hash"]["nested"]["any"]).to eq("value")
        end

        expect(result.timestamp).to eq(time)
        expect(result.valid_at).to eq(time)
      end

      specify "#dump with indifferent access" do
        time = Time.now
        hash =
          ActiveSupport::HashWithIndifferentAccess.new(
            {
              simple: "data",
              array: [1, 2, 3, ActiveSupport::HashWithIndifferentAccess.new({ some: "hash" })],
              hash:
                ActiveSupport::HashWithIndifferentAccess.new(
                  { nested: ActiveSupport::HashWithIndifferentAccess.new({ any: "value" }), meh: 3 }
                )
            }
          )
        result = WithIndifferentAccess.new.dump(record(hash, time))

        expect(result.data).to be_a(Hash)
        expect(result.metadata).to be_a(Hash)
        expect(result.data[:array].last).to be_a(Hash)
        expect(result.data[:hash]).to be_a(Hash)
        expect(result.data[:hash][:nested]).to be_a(Hash)

        [result.data, result.metadata].each do |d|
          expect(d[:simple]).to eq("data")
          expect(d[:array].first).to eq(1)
          expect(d[:array].last[:some]).to eq("hash")
          expect(d[:hash][:meh]).to eq(3)
          expect(d[:hash][:nested][:any]).to eq("value")
        end

        expect(result.timestamp).to eq(time)
        expect(result.valid_at).to eq(time)
      end

      specify "#dump with stringified hash" do
        time = Time.now
        hash = {
          "simple" => "data",
          "array" => [1, 2, 3, { "some" => "hash" }],
          "hash" => {
            "nested" => {
              "any" => "value"
            },
            "meh" => 3
          }
        }
        result = WithIndifferentAccess.new.dump(record(hash, time))

        expect(result.data).to be_a(Hash)
        expect(result.metadata).to be_a(Hash)
        expect(result.data[:array].last).to be_a(Hash)
        expect(result.data[:hash]).to be_a(Hash)
        expect(result.data[:hash][:nested]).to be_a(Hash)

        [result.data, result.metadata].each do |d|
          expect(d[:simple]).to eq("data")
          expect(d[:array].first).to eq(1)
          expect(d[:array].last[:some]).to eq("hash")
          expect(d[:hash][:meh]).to eq(3)
          expect(d[:hash][:nested][:any]).to eq("value")
        end

        expect(result.timestamp).to eq(time)
        expect(result.valid_at).to eq(time)
      end
    end
  end
end
