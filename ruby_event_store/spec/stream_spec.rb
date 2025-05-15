# frozen_string_literal: true

require "spec_helper"

module RubyEventStore
  ::RSpec.describe Stream do
    specify { expect(Stream.new("some_stream").name).to eq("some_stream") }
    specify { expect { Stream.new("") }.to raise_error(IncorrectStreamData) }
    specify { expect { Stream.new(nil) }.to raise_error(IncorrectStreamData) }
    specify { expect(Stream.new(GLOBAL_STREAM).global?).to be(true) }
    specify { expect(Stream.new("all").global?).to be(false) }
    specify { expect(Stream.new("meh").global?).to be(false) }

    specify "in-equality" do
      %w[possible stream names].permutation(2).each do |one, two|
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
  end
end
