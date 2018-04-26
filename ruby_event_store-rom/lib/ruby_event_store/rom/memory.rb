require 'rom/memory'
require_relative 'adapters/memory/unit_of_work'
require_relative 'adapters/memory/relations/events'
require_relative 'adapters/memory/relations/stream_entries'

module RubyEventStore
  module ROM
    module Memory
      class << self
        def fetch_next_id
          @last_id ||= 0
          @mutex ||= Mutex.new
          @mutex.synchronize { @last_id += 1 }
        end

        def setup(config)
          config.register_relation Relations::Events
          config.register_relation Relations::StreamEntries
        end

        def configure(env)
          env.register_unit_of_work_options(class: UnitOfWork)

          env.register_error_handler :unique_violation, -> ex {
            case ex
            when TupleUniquenessError
              raise EventDuplicatedInStream if ex.message =~ /stream.*event_id/
              raise WrongExpectedEventVersion
            end
          }
        end
      end

      class SpecHelper
        attr_reader :env
        
        def initialize(rom: RubyEventStore::ROM.env)
          @env = rom
        end

        def gateway
          env.container.gateways[:default]
        end

        def establish_gateway_connection
        end
      
        def load_gateway_schema
        end
      
        def drop_gateway_schema
          gateway.connection.data.values.each { |v| v.data.clear }
        end
      
        def close_gateway_connection
          gateway.disconnect
        end
      end
    end
  end
end
