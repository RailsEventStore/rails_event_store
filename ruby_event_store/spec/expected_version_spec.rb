# frozen_string_literal: true

require "spec_helper"

module RubyEventStore
  ::RSpec.describe ExpectedVersion do
    specify { expect(ExpectedVersion.any).to eq(ExpectedVersion.new(:any)) }

    specify { expect(ExpectedVersion.none).to eq(ExpectedVersion.new(:none)) }

    specify { expect(ExpectedVersion.auto).to eq(ExpectedVersion.new(:auto)) }

    specify { expect { ExpectedVersion.new(nil) }.to raise_error(InvalidExpectedVersion) }

    specify { expect { ExpectedVersion.new("13") }.to raise_error(InvalidExpectedVersion) }

    specify { expect(ExpectedVersion.new(:any).any?).to be(true) }

    specify { expect(ExpectedVersion.new(1).any?).to be(false) }

    specify { expect(ExpectedVersion.new(:auto).auto?).to be(true) }

    specify { expect(ExpectedVersion.new(1).auto?).to be(false) }

    specify { expect(ExpectedVersion.new(:none).none?).to be(true) }

    specify { expect(ExpectedVersion.new(1).none?).to be(false) }

    specify { expect(ExpectedVersion.any.resolve_for(Stream.new(GLOBAL_STREAM))).to be_nil }

    specify do
      expect { ExpectedVersion.auto.resolve_for(Stream.new(GLOBAL_STREAM)) }.to raise_error(InvalidExpectedVersion)
    end

    specify { expect(ExpectedVersion.none.resolve_for(Stream.new("dummy"))).to eq(ExpectedVersion::POSITION_DEFAULT) }

    specify { expect(ExpectedVersion.new(2).resolve_for(Stream.new("dummy"))).to eq(2) }

    specify { expect(ExpectedVersion.any.resolve_for(Stream.new("dummy"))).to be_nil }

    specify do
      resolver = ->(stream) do
        case stream.name
        when "42"
          42
        else
          13
        end
      end

      expect(ExpectedVersion.auto.resolve_for(Stream.new("42"), resolver)).to eq(42)
      expect(ExpectedVersion.auto.resolve_for(Stream.new("dummy"), resolver)).to eq(13)
    end

    specify do
      stream = Stream.new("some")
      expect(ExpectedVersion.auto.resolve_for(stream)).to eq(ExpectedVersion::POSITION_DEFAULT)
    end

    specify do
      stream = Stream.new("some")
      expect(ExpectedVersion.auto.resolve_for(stream, Proc.new {})).to eq(ExpectedVersion::POSITION_DEFAULT)
    end

    specify "in-equality" do
      %i[any none auto]
        .permutation(2)
        .each do |one, two|
          a = ExpectedVersion.new(one)
          b = ExpectedVersion.new(two)
          c = Class.new(ExpectedVersion).new(one)
          expect(a).not_to eq(b)
          expect(a).not_to eql(b)
          expect(a.hash).not_to eq(b.hash)

          expect(a).not_to eq(c)
          expect(a).not_to eql(c)
          expect(a.hash).not_to eq(c.hash)
        end
    end

    specify "equality" do
      a = ExpectedVersion.new(:any)
      b = ExpectedVersion.new(:any)
      expect(a).to eq(b)
      expect(a).to eql(b)
      expect(a.hash).to eql(b.hash)
    end
  end
end
