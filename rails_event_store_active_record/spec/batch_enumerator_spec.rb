require 'spec_helper'
require 'rails_event_store_active_record/batch_enumerator'

module RailsEventStoreActiveRecord
  RSpec.describe BatchEnumerator do
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

    def reader
      ->(offset,limit) { collection.drop(offset).take(limit) }
    end

    def collection
      (1..10000).to_a
    end
  end
end
