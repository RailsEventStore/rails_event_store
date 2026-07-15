# frozen_string_literal: true

module RubyEventStore
  module ActiveRecord
    module RailsGeneratorMethods
      private

      def adapter_name
        ::ActiveRecord::Base.connection.adapter_name
      end

      def migration_version
        ::ActiveRecord::Migration.current_version
      end

      def timestamp(time = Time.now)
        time.strftime("%Y%m%d%H%M%S")
      end
    end
  end
end
