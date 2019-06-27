# frozen_string_literal: true

module RubyEventStore
  module ROM
    module Changesets
      class CreateEvents < ::ROM::Changeset::Create
        module Defaults
          def self.included(base)
            base.class_eval do
              relation :events

              # Convert to Hash
              map(&:to_h)

              map do
                rename_keys event_id: :id
                accept_keys %i[id data metadata event_type]
              end

              map do |tuple|
                Hash(created_at: RubyEventStore::ROM::Types::DateTime.call(nil)).merge(tuple)
              end
            end
          end
        end

        include Defaults
      end
    end
  end
end
