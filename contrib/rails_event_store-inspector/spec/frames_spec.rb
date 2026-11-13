# frozen_string_literal: true

require "securerandom"

module RailsEventStore
  module Inspector
    ::RSpec.describe Frames do
      let(:frames) { Frames.new(:"frames_#{SecureRandom.hex(4)}") }

      specify "top reports the most recently pushed frame" do
        frames.push(:outer)
        frames.push(:inner)

        expect(frames.top).to eq(:inner)
      end

      specify "pop returns and removes the top frame" do
        frames.push(:outer)
        frames.push(:inner)

        expect(frames.pop).to eq(:inner)
        expect(frames.top).to eq(:outer)
      end

      specify "empty stack answers with nil rather than raising" do
        expect(frames.pop).to be_nil
        expect(frames.top).to be_nil
      end

      specify "each thread gets its own stack" do
        frames.push(:main_thread)

        seen =
          Thread.new do
            frames.push(:other_thread)
            frames.top
          end.value

        expect(seen).to eq(:other_thread)
        expect(frames.top).to eq(:main_thread)
      end
    end
  end
end
