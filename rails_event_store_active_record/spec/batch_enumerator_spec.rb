require 'spec_helper'
require 'rails_event_store_active_record/batch_enumerator'

module RailsEventStoreActiveRecord
  C = Struct.new(:id)

  RSpec.describe BatchEnumerator, timeout: 1 do
    before(:each) {
      $pry = false
    }
    let(:collection) { (1..10000).to_a.map {|i| C.new(i) } }
    let(:builder) { ->(c) { c.id } }
    let(:reader) do
      lambda do |offset_id, limit|
        start = offset_id.nil? ? 0 : collection.index(collection.find {|c| c.id > offset_id}) || collection.count
        collection.slice(start, limit)
      end
    end

    specify { expect(BatchEnumerator.new(100, 900, reader, builder).each).to be_kind_of(Enumerator) }
    specify { expect(BatchEnumerator.new(100, 900, reader, builder).to_a.size).to eq(9) }
    specify { expect(BatchEnumerator.new(100, 901, reader, builder).to_a.size).to eq(10) }
    specify { expect(BatchEnumerator.new(100, 1000, reader, builder).to_a.size).to eq(10) }
    specify { expect(BatchEnumerator.new(100, 1000, reader, builder).first.size).to eq(100) }
    specify { expect(BatchEnumerator.new(100, 1000, reader, builder).first).to eq((1..100).to_a) }
    specify { expect(BatchEnumerator.new(100, 1001, reader, builder).to_a.size).to eq(11) }
    specify { expect(BatchEnumerator.new(100, 10, reader, builder).to_a.size).to eq(1) }
    specify { expect(BatchEnumerator.new(100, 10, reader, builder).first.size).to eq(10) }
    specify { expect(BatchEnumerator.new(100, 10, reader, builder).first).to eq((1..10).to_a) }
    specify { expect(BatchEnumerator.new(1, 1000, reader, builder).to_a.size).to eq(1000) }
    specify { expect(BatchEnumerator.new(1, 1000, reader, builder).first.size).to eq(1) }
    specify { expect(BatchEnumerator.new(1, 1000, reader, builder).first).to eq([1]) }
    specify { expect(BatchEnumerator.new(100, Float::INFINITY, reader, builder).to_a.size).to eq(100) }
    specify { expect(BatchEnumerator.new(100, 99, reader, builder).to_a.size).to eq(1) }
    specify { expect(BatchEnumerator.new(100, 99, reader, builder).first.size).to eq(99) }
    specify { expect(BatchEnumerator.new(100, 199, reader, builder).to_a.size).to eq(2) }
    specify { expect(BatchEnumerator.new(100, 199, reader, builder).first.size).to eq(100) }
    specify { expect(BatchEnumerator.new(100, 199, reader, builder).first).to eq(collection[0..99].map(&builder)) }
    specify { expect(BatchEnumerator.new(100, 199, reader, builder).to_a[1].size).to eq(99) }
    specify { expect(BatchEnumerator.new(100, 199, reader, builder).to_a[1]).to eq(collection[100..198].map(&builder)) }
    specify do
      expect { |b| BatchEnumerator.new(1000, Float::INFINITY, reader, builder).each(&b) }.to yield_successive_args(
        collection[0...1000].map(&builder),
        collection[1000...2000].map(&builder),
        collection[2000...3000].map(&builder),
        collection[3000...4000].map(&builder),
        collection[4000...5000].map(&builder),
        collection[5000...6000].map(&builder),
        collection[6000...7000].map(&builder),
        collection[7000...8000].map(&builder),
        collection[8000...9000].map(&builder),
        collection[9000...10000].map(&builder)
      )
    end

    specify "ensure minimal required number of iterations" do
      expect(collection).to receive(:slice).once.and_call_original
      BatchEnumerator.new(100, 100, reader, builder).to_a
    end

    specify "ensure first reader call without offset_id" do
      expect(reader).to receive(:call).with(nil, kind_of(Integer)).and_return([]).and_call_original
      expect(reader).to receive(:call).with(kind_of(Integer), kind_of(Integer)).and_return([])
      BatchEnumerator.new(100, Float::INFINITY, reader, builder).to_a
    end
  end
end
