# frozen_string_literal: true

module RubyEventStore
  module ROM
    module Changesets
      class CreateStreamEntries < ::ROM::Changeset::Create
        relation :stream_entries

        map { |tuple| Hash(created_at: RubyEventStore::ROM::Types::DateTime.call(nil)).merge(tuple) }
        map { map_value :created_at, ->(datetime) { datetime.to_time.localtime } }
      end
    end
  end
end
