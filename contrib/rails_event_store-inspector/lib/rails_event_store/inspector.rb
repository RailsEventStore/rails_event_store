# frozen_string_literal: true

require_relative "inspector/version"
require_relative "inspector/buffer"
require_relative "inspector/frames"

module RailsEventStore
  module Inspector
    class << self
      def buffer
        @buffer ||= Buffer.new
      end
    end
  end
end
