# frozen_string_literal: true

require "spec_helper"
require "ruby_event_store/batch_enumerator"

module RubyEventStore
  ::RSpec.describe BatchEnumerator, timeout: 1 do
    let(:collection) { (1..10_000).to_a }
    let(:reader) { ->(offset, limit) { collection.drop(offset).take(limit) } }

    specify { expect(BatchEnumerator.new(100, 900, reader).each).to be_kind_of(Enumerator) }
    specify { expect(BatchEnumerator.new(100, 900, reader).to_a.size).to eq(9) }
    specify { expect(BatchEnumerator.new(100, 901, reader).to_a.size).to eq(10) }
    specify { expect(BatchEnumerator.new(100, 1000, reader).to_a.size).to eq(10) }
    specify { expect(BatchEnumerator.new(100, 1000, reader).first.size).to eq(100) }
    specify { expect(BatchEnumerator.new(100, 1000, reader).first).to eq((1..100).to_a) }
    specify { expect(BatchEnumerator.new(100, 1001, reader).to_a.size).to eq(11) }
    specify { expect(BatchEnumerator.new(100, 10, reader).to_a.size).to eq(1) }
    specify { expect(BatchEnumerator.new(100, 10, reader).first.size).to eq(10) }
    specify { expect(BatchEnumerator.new(100, 10, reader).first).to eq((1..10).to_a) }
    specify { expect(BatchEnumerator.new(1, 1000, reader).to_a.size).to eq(1000) }
    specify { expect(BatchEnumerator.new(1, 1000, reader).first.size).to eq(1) }
    specify { expect(BatchEnumerator.new(1, 1000, reader).first).to eq([1]) }
    specify { expect(BatchEnumerator.new(100, Float::INFINITY, reader).to_a.size).to eq(100) }
    specify { expect(BatchEnumerator.new(100, 99, reader).to_a.size).to eq(1) }
    specify { expect(BatchEnumerator.new(100, 99, reader).first.size).to eq(99) }
    specify { expect(BatchEnumerator.new(100, 199, reader).to_a.size).to eq(2) }
    specify { expect(BatchEnumerator.new(100, 199, reader).first.size).to eq(100) }
    specify { expect(BatchEnumerator.new(100, 199, reader).first).to eq(collection[0..99]) }
    specify { expect(BatchEnumerator.new(100, 199, reader).to_a[1].size).to eq(99) }
    specify { expect(BatchEnumerator.new(100, 199, reader).to_a[1]).to eq(collection[100..198]) }
    specify do
      expect { |b| BatchEnumerator.new(1000, Float::INFINITY, reader).each(&b) }.to yield_successive_args(
        collection[0...1000],
        collection[1000...2000],
        collection[2000...3000],
        collection[3000...4000],
        collection[4000...5000],
        collection[5000...6000],
        collection[6000...7000],
        collection[7000...8000],
        collection[8000...9000],
        collection[9000...10_000]
      )
    end

    specify "ensure minimal required number of iterations" do
      expect(collection).to receive(:drop).once.and_call_original
      BatchEnumerator.new(100, 100, reader).to_a
    end

    specify do
      expect(reader = double(:reader)).to receive(:call).with(kind_of(Numeric), kind_of(Numeric)).and_return([])
      BatchEnumerator.new(100, Float::INFINITY, reader).to_a
    end

    specify "ensure not fetching next batch if the previous one was smaller than specified batch size" do
      expect(reader).to receive(:call).exactly(4).times.and_call_original
      expect(BatchEnumerator.new(3000, Float::INFINITY, reader).to_a)
    end
  end
end
