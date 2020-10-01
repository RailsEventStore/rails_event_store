require 'spec_helper'

module RubyEventStore

  RSpec.describe Record do
    let(:event_id)   { "event_id" }
    let(:data)       { "data" }
    let(:metadata)   { "metadata" }
    let(:event_type) { "event_type" }
    let(:timestamp)  { "2019-10-03T22:25:22.000000Z" }
    let(:time)       { Time.utc(2019, 10, 03, 22, 25, 22) }

    specify 'constructor accept all arguments and returns frozen instance' do
      record = described_class.new(event_id: event_id, data: data, metadata: metadata, event_type: event_type, timestamp: timestamp, valid_at: timestamp)
      expect(record.event_id).to   be event_id
      expect(record.metadata).to   be metadata
      expect(record.data).to       be data
      expect(record.event_type).to be event_type
      expect(record.frozen?).to    be true
    end

    specify 'constructor raised Record::StringsRequired when argument is not a String' do
      [[1, 1, 1, 1],
       [1, "string", "string", "string"],
       ["string", "string", "string", 1]].each do |sample|
        event_id, data, metadata, event_type = sample
        expect do
          described_class.new(event_id: event_id, data: data, metadata: metadata, event_type: event_type, timestamp: timestamp, valid_at: timestamp)
        end.to raise_error Record::StringsRequired
      end
    end

    specify "in-equality" do
      [
        ["a", "a", "a", "a", "a", "a"],
        ["b", "a", "a", "a", "a", "a"],
        ["a", "b", "a", "a", "a", "a"],
        ["a", "a", "b", "a", "a", "a"],
        ["a", "a", "a", "b", "a", "a"],
        ["a", "a", "a", "a", "b", "a"],
        ["a", "a", "a", "a", "a", "b"],
      ].permutation(2).each do |one, two|
        a = Record.new(event_id: one[0], data: one[1], metadata: one[2], event_type: one[3], timestamp: one[4], valid_at: one[5])
        b = Record.new(event_id: two[0], data: two[1], metadata: two[2], event_type: two[3], timestamp: two[4], valid_at: two[5])
        c = Class.new(Record).new(event_id: one[0], data: one[1], metadata: one[2], event_type: one[3], timestamp: one[4], valid_at: one[5])
        expect(a).not_to eq(b)
        expect(a).not_to eql(b)
        expect(a.hash).not_to eq(b.hash)
        h = {a => :val}
        expect(h[b]).to be_nil

        expect(a).not_to eq(c)
        expect(a).not_to eql(c)
        expect(a.hash).not_to eq(c.hash)
        h = {a => :val}
        expect(h[c]).to be_nil
      end
    end

    specify "equality" do
      a = Record.new(event_id: "a", data: "b", metadata: "c", event_type: "d", timestamp: "e", valid_at: "f")
      b = Record.new(event_id: "a", data: "b", metadata: "c", event_type: "d", timestamp: "e", valid_at: "f")
      expect(a).to eq(b)
      expect(a).to eql(b)
      expect(a.hash).to eql(b.hash)
      h = {a => :val}
      expect(h[b]).to eq(:val)
    end

    specify "hash" do
      a = Record.new(event_id: "a", data: "b", metadata: "c", event_type: "d", timestamp: "e", valid_at: "f")
      expect(a.hash).not_to eq([Record, "a", "b", "c", "d", "e", "f"].hash)
    end

    specify "to_h" do
      a = Record.new(event_id: "a", data: "b", metadata: "c", event_type: "d", timestamp: "e", valid_at: "f")
      expect(a.to_h).to eq({
        event_id: "a",
        data: "b",
        metadata: "c",
        event_type: "d",
        timestamp: "e",
        valid_at: "f",
      })
    end

    specify 'constructor raised when required args are missing' do
      expect do
        described_class.new
      end.to raise_error ArgumentError
    end

    specify '#serialize' do
      actual  = Record.new(event_id: "a", data: "b", metadata: "c", event_type: "d", timestamp: time, valid_at: time)
      expected = SerializedRecord.new(event_id: "a", data: "--- b\n", metadata: "--- c\n", event_type: "d", timestamp: timestamp, valid_at: timestamp)
      expect(actual.serialize(YAML)).to eq(expected)
    end
  end
end

