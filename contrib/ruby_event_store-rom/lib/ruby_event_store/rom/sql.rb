# frozen_string_literal: true

module RubyEventStore
  module ROM
    module SQL
      class << self
        def setup(config)
          config.register_mapper(Mappers::StreamEntryToSerializedRecord)
          config.register_mapper(Mappers::EventToSerializedRecord)
          config.register_relation Relations::Events
          config.register_relation Relations::StreamEntries
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
    end
  end
end
