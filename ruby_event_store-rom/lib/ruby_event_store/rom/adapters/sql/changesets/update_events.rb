# frozen_string_literal: true

module RubyEventStore
  module ROM
    module SQL
      module Changesets
        class UpdateEvents < ::ROM::Changeset::Create
          include ROM::Changesets::UpdateEvents::Defaults

          UPSERT_COLUMNS = %i[event_type data metadata valid_at].freeze

          def commit
            if SQL.supports_on_duplicate_key_update?(relation.dataset.db)
              commit_on_duplicate_key_update
            elsif SQL.supports_insert_conflict_update?(relation.dataset.db)
              commit_insert_conflict_update
            else
              raise "Database doesn't support upserts: #{relation.dataset.db.adapter_scheme}"
            end
          end

          private

          def commit_on_duplicate_key_update
            relation.dataset.on_duplicate_key_update(*UPSERT_COLUMNS).multi_insert(to_a)
          end

          def commit_insert_conflict_update
            relation.dataset.insert_conflict(
              # constraint: 'index_name',
              target: :event_id,
              update: UPSERT_COLUMNS.each_with_object({}) do |column, memo|
                memo[column] = Sequel[:excluded][column]
              end
            ).multi_insert(to_a)
          end
        end
      end
    end
  end
end
