module RubyEventStore
  module ROM
    module SQL
      module Changesets
        class UpdateEvents < ::ROM::Changeset::Create
          include ROM::Changesets::UpdateEvents::Defaults

          def commit
            case relation.dataset.db.adapter_scheme
            when /mysql/
              commit_on_duplicate_key_update
            when /postgres/, /sqlite/
              commit_insert_conflict
            else
              raise "Database doesn't support upserts: #{gateway.database_type}"
            end
          end

          private

          def commit_on_duplicate_key_update
            relation.dataset.on_duplicate_key_update(:id).multi_insert(to_a)
          end

          def commit_insert_conflict
            relation.dataset.insert_conflict(
              # constraint: 'index_name',
              target: :id,
              update: {
                data:       Sequel[:excluded][:data],
                metadata:   Sequel[:excluded][:metadata],
                event_type: Sequel[:excluded][:event_type],
                created_at: Sequel[:excluded][:created_at]
              }
            ).multi_insert(to_a)
          end
        end
      end
    end
  end
end
