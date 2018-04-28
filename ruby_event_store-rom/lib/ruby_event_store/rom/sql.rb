require 'ruby_event_store/rom'
require 'rom/sql'
require_relative 'adapters/sql/index_violation_detector'
require_relative 'adapters/sql/unit_of_work'
require_relative 'adapters/sql/relations/events'
require_relative 'adapters/sql/relations/stream_entries'

module RubyEventStore
  module ROM
    module SQL
      class << self
        def setup(config)
          config.register_relation Relations::Events
          config.register_relation Relations::StreamEntries
        end

        def configure(env)
          # See: https://github.com/jeremyevans/sequel/blob/master/doc/transactions.rdoc
          env.register_unit_of_work_options(
            class: UnitOfWork,
            savepoint: true
          )

          env.register_error_handler :unique_violation, -> ex {
            case ex
            when ::ROM::SQL::UniqueConstraintError, Sequel::UniqueConstraintViolation
              raise EventDuplicatedInStream if IndexViolationDetector.new.detect(ex.message)
              raise WrongExpectedEventVersion
            end
          }

          env.register_error_handler :not_found, -> (ex, event_id) {
            case ex
            when ::ROM::TupleCountMismatchError
              raise EventNotFound.new(event_id)
            when Sequel::DatabaseError
              raise ex unless ex.message =~ /PG::InvalidTextRepresentation.*uuid/
              raise EventNotFound.new(event_id)
            end
          }
        end
      end

      class SpecHelper
        attr_reader :env
        
        def initialize
          config = ::ROM::Configuration.new(
            :sql,
            ENV['DATABASE_URL'],
            max_connections: ENV['DATABASE_URL'] =~ /sqlite/ ? 1 : 5,
            preconnect: :concurrently,
            # sql_mode: %w[NO_AUTO_VALUE_ON_ZERO STRICT_ALL_TABLES]
          )
          # $stdout.sync = true
          # config.default.use_logger Logger.new(STDOUT)
          # config.default.connection.pool.send(:preconnect, true)
          config.default.run_migrations
    
          @env = RubyEventStore::ROM.setup(config)
        end
        
        def run_lifecycle
          establish_gateway_connection
          load_gateway_schema

          yield
        ensure
          drop_gateway_schema
          close_gateway_connection
        end

        def gateway
          env.container.gateways.fetch(:default)
        end

        def has_connection_pooling?
          gateway.connection.database_type != :sqlite
        end

        def connection_pool_size
          gateway.connection.pool.size
        end

        def close_pool_connection
          gateway.connection.pool.disconnect
        end

      protected

        def establish_gateway_connection
          # Manually preconnect because disconnecting and reconnecting
          # seems to lose the "preconnect concurrently" setting
          gateway.connection.pool.send(:preconnect, true)
        end

        def load_gateway_schema
          gateway.run_migrations
        end

        def drop_gateway_schema
          gateway.connection.drop_table?('event_store_events')
          gateway.connection.drop_table?('event_store_events_in_streams')
          gateway.connection.drop_table?('schema_migrations')
        end

        # See: https://github.com/rom-rb/rom-sql/blob/master/spec/shared/database_setup.rb
        def close_gateway_connection
          gateway.connection.disconnect
          # Prevent the auto-reconnect when the test completed
          # This will save from hardly reproducible connection run outs
          gateway.connection.pool.available_connections.freeze
        end
      end
    end
  end
end
