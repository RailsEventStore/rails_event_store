require 'spec_helper'

module RubyEventStore
  RSpec.describe Metadata do

    specify 'default values' do
      expect(Metadata.new.each.to_a).to be_empty
      expect(Metadata.new({a: 'b'}).each.to_a).to eq([[:a, 'b']])
    end

    specify 'allowed values' do
      m = Metadata.new
      m[:key] = "string"
      expect(m[:key]).to eq("string")

      m[:key] = 1
      expect(m[:key]).to eq(1)

      m[:key] = 2**40
      expect(m[:key]).to eq(2**40)

      m[:key] = 5.5
      expect(m[:key]).to eq(5.5)

      m[:key] = Date.today
      expect(m[:key]).to eq(Date.today)

      m[:key] = t = Time.now
      expect(m[:key]).to eq(t)

      m[:key] = true
      expect(m[:key]).to eq(true)

      m[:key] = false
      expect(m[:key]).to eq(false)

      m[:key] = nil
      expect(m[:key]).to eq(nil)

      m[:key] = {some: 'hash', with: {nested: 'values'}}
      expect(m[:key]).to eq({some: 'hash', with: {nested: 'values'}})

      m[:key] = [1,2,3]
      expect(m[:key]).to eq([1,2,3])

      expect do
        m[:key] = Object.new
      end.to raise_error(ArgumentError)

      expect do
        m['key'] = 1
      end.to raise_error(ArgumentError)
    end

    specify 'allowed keys' do
      m = Metadata.new

      expect do
        m[:key]
      end.not_to raise_error

      expect do
        m[Object.new]
      end.to raise_error(ArgumentError)
    end

    specify 'each' do
      m = Metadata.new
      m[:a] = 1
      m[:b] = "2"

      expect do |b|
        m.each(&b)
      end.to yield_successive_args([:a, 1], [:b, "2"])
    end

    specify 'to_h' do
      m = Metadata.new
      m[:a] = 1
      m[:b] = "2"
      expect(m.to_h).to eq({a: 1, b: "2"})

      h = m.to_h
      h[:x] = "leaked?"
      expect(m[:x]).to be_nil
    end

    specify 'Enumerable' do
      m = Metadata.new
      m[:a] = 1
      expect(m.map{|k,v| [k,v] }).to eq([[:a, 1]])
    end

    specify 'safe Hash methods' do
      m = Metadata.new
      m[:a] = 1
      expect(m.key?(:a)).to eq(true)
    end

  end
end
