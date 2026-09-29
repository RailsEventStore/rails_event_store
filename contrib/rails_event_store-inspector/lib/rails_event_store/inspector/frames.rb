# frozen_string_literal: true

module RailsEventStore
  module Inspector
    class Frames
      def initialize(key)
        @key = key
      end

      def push(frame)
        frames.push(frame)
      end

      def pop
        frames.pop
      end

      def top
        frames.last
      end

      private

      def frames
        Thread.current[@key] ||= []
      end
    end
  end
end
