module RailsEventStore
  module Repositories
    class Repository

      def initialize(adapter)
        @adapter = adapter
      end

      def create(model)
        adapter.create model
      end

      def delete(condition)
        adapter.destroy_all condition
      end

      private
      attr_reader :adapter

    end
  end
end