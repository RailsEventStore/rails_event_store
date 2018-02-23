module RubyEventStore
  module Repositories
    class Null
      def initialize(repository_to_mimic = InMemory.new)
        @repository_to_mimic = repository_to_mimic
      end

      def method_missing(method_name, *_)
        super unless respond_to_missing?(method_name)
      end

      def respond_to_missing?(method_name, include_private = false)
        @repository_to_mimic.respond_to?(method_name, include_private)
      end
    end
  end
end
