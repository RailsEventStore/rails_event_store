# frozen_string_literal: true

require 'ruby_event_store/rom'
require 'rom/sql'
require_relative 'adapters/sql/index_violation_detector'
require_relative 'adapters/sql/relations/events'
require_relative 'adapters/sql/relations/stream_entries'
require_relative 'adapters/sql/changesets/create_events'
require_relative 'adapters/sql/changesets/update_events'

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
            savepoint: true,
            # Committing changesets concurrently causes MySQL deadlocks
            # which are not caught and retried by Sequel's built-in
            # :retry_on option. This appears to be a result of how ROM
            # handles exceptions which don't bubble up so that Sequel
            # can retry transactions with the :retry_on option when there's
            # a deadlock.
            #
            # This is exacerbated by the fact that changesets insert multiple
            # tuples with individual INSERT statements because ROM specifies
            # to Sequel to return a list of primary keys created. The likelihood
            # of a deadlock is reduced with batched INSERT statements.
            #
            # For this reason we need to manually insert changeset records to avoid
            # MySQL deadlocks or to allow Sequel to retry transactions
            # when the :retry_on option is specified.
            retry_on: Sequel::SerializationFailure,
            before_retry: lambda { |_num, ex|
              env.logger.warn("RETRY TRANSACTION [#{self.class.name} => #{ex.class.name}] #{ex.message}")
            }
          )

          env.register_error_handler :unique_violation, lambda { |ex|
            case ex
            when ::ROM::SQL::UniqueConstraintError, Sequel::UniqueConstraintViolation
              raise EventDuplicatedInStream if IndexViolationDetector.new.detect(ex.message)

              raise WrongExpectedEventVersion
            end
          }

          env.register_error_handler :not_found, lambda { |ex, event_id|
            case ex
            when ::ROM::TupleCountMismatchError
              raise EventNotFound, event_id
            when Sequel::DatabaseError
              raise ex unless ex.message =~ /PG::InvalidTextRepresentation.*uuid/

              raise EventNotFound, event_id
            end
          }
        end

        def supports_upsert?(db)
          supports_on_duplicate_key_update?(db) ||
            supports_insert_conflict_update?(db)
        end

        def supports_on_duplicate_key_update?(db)
          db.adapter_scheme =~ /mysql/
        end

        def supports_insert_conflict_update?(db)
          case db.adapter_scheme
          when :postgres
            true
          when :sqlite
            # Sqlite 3.24.0+ supports PostgreSQL upsert syntax
            db.sqlite_version >= 32_400
          else
            false
          end
        end
      end

      class SpecHelper
        attr_reader :env

        def initialize(database_uri = ENV['DATABASE_URL'])
          config = ::ROM::Configuration.new(
            :sql,
            database_uri,
            max_connections: database_uri =~ /sqlite/ ? 1 : 5,
            preconnect: :concurrently,
            fractional_seconds: true
            # sql_mode: %w[NO_AUTO_VALUE_ON_ZERO STRICT_ALL_TABLES]
          )
          # $stdout.sync = true
          # config.default.use_logger Logger.new(STDOUT)
          # config.default.connection.pool.send(:preconnect, true)
          config.default.run_migrations

          @env = ROM.setup(config)
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
          env.rom_container.gateways.fetch(:default)
        end

        def gateway_type?(name)
          gateway.connection.database_type.eql?(name)
        end

        def has_connection_pooling?
          !gateway_type?(:sqlite)
        end

        def connection_pool_size
          gateway.connection.pool.size
        end

        def close_pool_connection
          gateway.connection.pool.disconnect
        end

        def supports_upsert?
          SQL.supports_upsert?(gateway.connection)
        end

        def supports_concurrent_any?
          has_connection_pooling?
        end

        def supports_concurrent_auto?
          has_connection_pooling?
        end

        def supports_binary?
          false
        end

        def rescuable_concurrency_test_errors
          [::ROM::SQL::Error]
        end

        def cleanup_concurrency_test
          close_pool_connection
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
