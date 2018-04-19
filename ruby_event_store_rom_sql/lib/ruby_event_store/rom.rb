require 'rom/sql'
require 'rom-changeset'
require 'rom-mapper'
require 'rom-repository'
require 'ruby_event_store'
require 'ruby_event_store/rom/event_repository'
require 'ruby_event_store/rom/version'

module RubyEventStore
  module ROM
    class << self
      # Set to a default instance
      attr_accessor :env
  
      def configure(database_uri = ENV['DATABASE_URL'], &block)
        if database_uri.is_a?(::ROM::Configuration)
          # Call config block manually
          ::ROM.container(database_uri.tap(&block), &block)
        else
          ::ROM.container(:sql, database_uri, &block)
        end
      end
  
      def setup(*args, &block)
        configure(*args) do |config|
          apply_defaults(config)
  
          block.call(config) if block
        end
      end
  
      # ROM::Configuration
      def apply_defaults(config)
        require_relative 'rom/repositories/stream_entries'
        require_relative 'rom/repositories/events'
        
        config.register_mapper(ROM::Mappers::EventToSerializedRecord)
        config.register_mapper(ROM::Mappers::StreamEntryToSerializedRecord)
      end
    end
  end
end
