module RailsEventStore
  module Repositories
    class Repository

      def initialize(adapter)
        @adapter = adapter
      end

      def find(condition)
        adapter.where(condition).first
      end

      def create(data)
        model = adapter.new(data)
        raise EventCannotBeSaved unless model.valid?
        model.save
      end

      def delete(condition)
        adapter.destroy_all condition
      end

      private
      attr_reader :adapter

    end
  end
end