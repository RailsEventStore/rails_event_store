# frozen_string_literal: true

module RailsEventStore
  module Inspector
    module Insertion
      def self.call(stack, middleware)
        stack.use(middleware)
      end
    end
  end
end
