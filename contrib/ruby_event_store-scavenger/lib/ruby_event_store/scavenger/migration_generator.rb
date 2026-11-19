# frozen_string_literal: true

require "erb"

module RubyEventStore
  module Scavenger
    # Writes the migration that creates event_store_scavenger_state.
    class MigrationGenerator
      NAME = "create_event_store_scavenger_state"
      TEMPLATE = File.expand_path("templates/#{NAME}_template.erb", __dir__)

      # @return [String] path of the migration file
      def call(migration_path, time: Time.now)
        path = File.join(migration_path, "#{time.strftime("%Y%m%d%H%M%S")}_#{NAME}.rb")
        File.write(path, migration_code)
        path
      end

      def migration_code
        ERB.new(File.read(TEMPLATE)).result_with_hash(migration_version: ::ActiveRecord::Migration.current_version)
      end
    end
  end
end
