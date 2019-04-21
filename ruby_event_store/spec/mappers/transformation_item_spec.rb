require 'spec_helper'

module RubyEventStore
  module Mappers
    RSpec.describe TransformationItem do

      specify 'initial values' do
        expect(TransformationItem.new(a: 1, b: 'any').to_h).to eq({a: 1, b: 'any'})
      end

      specify '#event_id' do
        expect(TransformationItem.new(event_id: '123').event_id).to eq('123')
      end

      specify '#data' do
        expect(TransformationItem.new(data: {any: 'thing'}).data).to eq({any: 'thing'})
      end

      specify '#metadata' do
        expect(TransformationItem.new(metadata: {any: 'thing'}).metadata).to eq({any: 'thing'})
      end

      specify '#event_type' do
        expect(TransformationItem.new(event_type: 'Some').event_type).to eq('Some')
      end

      specify '#[]' do
        item1 = TransformationItem.new(key: 'string')
        expect(item1[:key]).to eq("string")
      end

      specify '#to_h' do
        item = TransformationItem.new({a: 1, b: '2'})
        expect(item.to_h).to eq({a: 1, b: '2'})

        h = item.to_h
        h[:x] = "leaked?"
        expect(item[:x]).to be_nil
      end

      specify "#eql?" do
        item1 = TransformationItem.new({a: 1, b: '2'})
        item2 = TransformationItem.new({a: 1, b: '2'})
        item3 = TransformationItem.new({a: '1', b: 2})

        expect(item1).to eq(item2)
        expect(item1).not_to eq(item3)
        expect(item3).not_to eq(Object.new)
      end

      specify '#merge' do
        item1 = TransformationItem.new(a: 1)
        item2 = item1.merge(b: 'any')
        expect(item2.class).to eq(TransformationItem)
        expect(item1.object_id).not_to eq(item2.object_id)
        expect(item2.to_h).to eq({a: 1, b: 'any'})
        item3 = item2.merge(b: 'changed')
        expect(item3[:b]).to eq("changed")
      end
    end
  end
end
