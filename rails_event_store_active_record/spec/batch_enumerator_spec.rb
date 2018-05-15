require 'spec_helper'
require 'rails_event_store_active_record/batch_enumerator'

module RailsEventStoreActiveRecord
  RSpec.describe BatchEnumerator do
    let(:collection) { (1..10000).to_a }
    let(:reader) { ->(offset,limit) { collection.drop(offset).take(limit) } }

    specify { expect(BatchEnumerator.new(100, 900, reader).each.to_a.size).to eq(9) }
    specify { expect(BatchEnumerator.new(100, 901, reader).each.to_a.size).to eq(10) }
    specify { expect(BatchEnumerator.new(100, 1000, reader).each.to_a.size).to eq(10) }
    specify { expect(BatchEnumerator.new(100, 1000, reader).each.to_a[0].size).to eq(100) }
    specify { expect(BatchEnumerator.new(100, 1000, reader).each.to_a[0]).to eq((1..100).to_a) }
    specify { expect(BatchEnumerator.new(100, 1001, reader).each.to_a.size).to eq(11) }
    specify { expect(BatchEnumerator.new(100, 10, reader).each.to_a.size).to eq(1) }
    specify { expect(BatchEnumerator.new(100, 10, reader).each.to_a[0].size).to eq(10) }
    specify { expect(BatchEnumerator.new(100, 10, reader).each.to_a[0]).to eq((1..10).to_a) }
    specify { expect(BatchEnumerator.new(1, 1000, reader).each.to_a.size).to eq(1000) }
    specify { expect(BatchEnumerator.new(1, 1000, reader).each.to_a[0].size).to eq(1) }
    specify { expect(BatchEnumerator.new(1, 1000, reader).each.to_a[0]).to eq([1]) }
    specify { expect(BatchEnumerator.new(100, Float::INFINITY, reader).each.to_a.size).to eq(100) }
    specify { expect(BatchEnumerator.new(100, 99, reader).each.to_a.size).to eq(1) }
    specify { expect(BatchEnumerator.new(100, 99, reader).each.to_a[0].size).to eq(99) }
    specify { expect(BatchEnumerator.new(100, 199, reader).each.to_a.size).to eq(2) }
    specify { expect(BatchEnumerator.new(100, 199, reader).each.to_a[0].size).to eq(100) }
    specify { expect(BatchEnumerator.new(100, 199, reader).each.to_a[0]).to eq(collection[0..99]) }
    specify { expect(BatchEnumerator.new(100, 199, reader).each.to_a[1].size).to eq(99) }
    specify { expect(BatchEnumerator.new(100, 199, reader).each.to_a[1]).to eq(collection[100..198]) }
    specify do
      expect(collection).to receive(:drop).once.and_call_original
      BatchEnumerator.new(100, 100, reader).each.to_a
    end
  end
end
