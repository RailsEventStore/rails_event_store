# frozen_string_literal: true

require 'ruby_event_store'
require 'rom'
require 'rom/sql'
require 'rom/transformer'

require_relative 'rom/changesets/create_events'
require_relative 'rom/changesets/create_stream_entries'
require_relative 'rom/changesets/update_events'
require_relative 'rom/env'
require_relative 'rom/event_repository'
require_relative 'rom/index_violation_detector'
require_relative 'rom/mappers/event_to_serialized_record'
require_relative 'rom/mappers/stream_entry_to_serialized_record'
require_relative 'rom/relations/events'
require_relative 'rom/relations/stream_entries'
require_relative 'rom/repositories/events'
require_relative 'rom/repositories/stream_entries'
require_relative 'rom/sql'
require_relative 'rom/types'
require_relative 'rom/unit_of_work'

module RubyEventStore
  module ROM
    class << self
      # Set to a default instance
      attr_accessor :env

      def configure(adapter_name, database_uri = ENV['DATABASE_URL'], &block)
        if adapter_name.is_a?(::ROM::Configuration)
          # Call config block manually
          Env.new ::ROM.container(adapter_name.tap(&block), &block)
        else
          Env.new ::ROM.container(adapter_name, database_uri, &block)
        end
      end

      def setup(*args, &block)
        configure(*args) do |config|
          setup_defaults(config)
          yield(config) if block
        end.tap(&method(:configure_defaults))
      end

      private

      def setup_defaults(config)
        SQL.setup(config)
      end

      def configure_defaults(env)
        SQL.configure(env)
      end
    end
  end
end
