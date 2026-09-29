# frozen_string_literal: true

module RailsEventStore
  module Inspector
    ::RSpec.describe Buffer do
      specify "keeps what was pushed, in order" do
        buffer = Buffer.new

        buffer.push(kind: :a)
        buffer.push(kind: :b)

        expect(buffer.to_a).to eq([{ kind: :a }, { kind: :b }])
      end

      specify "drops the oldest entries past the limit" do
        buffer = Buffer.new(limit: 2)

        3.times { |i| buffer.push(kind: i) }

        expect(buffer.to_a).to eq([{ kind: 1 }, { kind: 2 }])
      end

      specify "clear empties it" do
        buffer = Buffer.new
        buffer.push(kind: :a)

        buffer.clear

        expect(buffer.to_a).to be_empty
      end

      specify "to_a hands out a copy, so callers cannot corrupt the buffer" do
        buffer = Buffer.new
        buffer.push(kind: :a)

        buffer.to_a << { kind: :sneaky }

        expect(buffer.to_a.size).to eq(1)
      end

      specify "concurrent writers do not lose entries nor exceed the limit" do
        buffer = Buffer.new(limit: 50)

        10.times.map { |t| Thread.new { 20.times { |i| buffer.push(kind: "#{t}-#{i}") } } }.each(&:join)

        expect(buffer.to_a.size).to eq(50)
      end
    end
  end
end
