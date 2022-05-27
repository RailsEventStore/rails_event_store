# frozen_string_literal: true

module RubyEventStore
  module ROM
    module Changesets
      class CreateEvents < ::ROM::Changeset::Create
        relation :events

        map(&:to_h)
        map do
          rename_keys timestamp: :created_at
          map_value :created_at, ->(time) { Time.iso8601(time).localtime }
          map_value :valid_at, ->(time) { Time.iso8601(time).localtime }
          accept_keys %i[event_id data metadata event_type created_at valid_at]
        end

        def commit
          relation.multi_insert(to_a)
        end
      end
    end
  end
end
