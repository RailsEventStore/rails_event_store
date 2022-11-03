require "spec_helper"

module RubyEventStore
  module Outbox
    RSpec.describe Tempo do
      specify "starts with 1" do
        tempo = Tempo.new(100)

        expect(tempo.batch_size).to eq(1)
      end

      specify "each batch size is bigger" do
        tempo = Tempo.new(100)
        first_value = tempo.batch_size
        second_value = tempo.batch_size
        third_value = tempo.batch_size

        expect(second_value).to be > first_value
        expect(third_value).to be > second_value
      end

      specify "batch_size stabilize" do
        max_batch_size = 100
        tempo = Tempo.new(max_batch_size)
        max_batch_size.times { tempo.batch_size }

        value101 = tempo.batch_size
        value102 = tempo.batch_size

        expect(value101).to eq(value102)
      end

      specify "maximum batch size cap is respected" do
        max_batch_size = 100
        tempo = Tempo.new(max_batch_size)
        100.times { tempo.batch_size }

        value101 = tempo.batch_size
        value102 = tempo.batch_size
        expect(value101).to eq(max_batch_size)
        expect(value102).to eq(max_batch_size)
      end

      specify "increase multiplier" do
        tempo = Tempo.new(100)

        first_value = tempo.batch_size
        second_value = tempo.batch_size

        expect(first_value * 2).to eq(second_value)
      end

      specify "disallows unreasonable size" do
        expect { Tempo.new(0) }.to raise_error(ArgumentError)
        expect { Tempo.new(0.5) }.to raise_error(ArgumentError)
        expect { Tempo.new(-1) }.to raise_error(ArgumentError)
        expect { Tempo.new(1) }.not_to raise_error
      end
    end
  end
end
