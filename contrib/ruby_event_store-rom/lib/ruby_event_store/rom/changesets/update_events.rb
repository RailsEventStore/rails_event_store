# frozen_string_literal: true

module RubyEventStore
  module ROM
    module Changesets
      class UpdateEvents < ::ROM::Changeset::Update
        relation :events

        map(&:to_h)
        map do
          rename_keys timestamp: :created_at
          map_value :created_at, ->(time) { Time.iso8601(time).localtime }
          map_value :valid_at, ->(time) { Time.iso8601(time).localtime }
          accept_keys %i[event_id data metadata event_type created_at valid_at]
        end

        UPSERT_COLUMNS = %i[event_type data metadata valid_at].freeze

        def commit
          supports_on_duplicate_key_update? ? commit_on_duplicate_key_update : commit_insert_conflict_update
        end

        private

        def supports_on_duplicate_key_update?
          relation.dataset.db.adapter_scheme =~ /mysql/
        end

        def commit_on_duplicate_key_update
          relation.dataset.on_duplicate_key_update(*UPSERT_COLUMNS).multi_insert(to_a)
        end

        def commit_insert_conflict_update
          relation
            .dataset
            .insert_conflict(
              target: :event_id,
              update: UPSERT_COLUMNS.each_with_object({}) { |column, memo| memo[column] = Sequel[:excluded][column] },
            )
            .multi_insert(to_a)
        end
      end
    end
  end
end
