require 'spec_helper'

module RubyEventStore
  RSpec.describe Stream do
    specify do
      stream = Stream.new("some_stream")
      expect(stream.name).to eq("some_stream")
    end

    specify "in-equality" do
      %w(
        possible
        stream
        names
      ).permutation(2).each do |one, two|
        a = Stream.new(one)
        b = Stream.new(two)
        c = Class.new(Stream).new(one)
        expect(a).not_to eq(b)
        expect(a).not_to eql(b)
        expect(a.hash).not_to eq(b.hash)

        expect(a).not_to eq(c)
        expect(a).not_to eql(c)
        expect(a.hash).not_to eq(c.hash)
      end
    end

    specify "equality" do
      a = Stream.new("some")
      b = Stream.new("some")
      expect(a).to eq(b)
      expect(a).to eql(b)
      expect(a.hash).to eql(b.hash)
    end

    specify "hash" do
      a = Stream.new("some")
      expect(a.hash).not_to eq([Stream, "some"].hash)
      expect(Set.new([a])).to eq(Set.new([a]))
    end
  end
end