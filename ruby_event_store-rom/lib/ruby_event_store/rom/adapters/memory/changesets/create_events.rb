# frozen_string_literal: true

module RubyEventStore
  module ROM
    module Memory
      module Changesets
        class CreateEvents < ROM::Changesets::CreateEvents
          def commit
            relation.by_pk(to_a.map { |e| e[:id] }).each do |tuple|
              raise TupleUniquenessError.for_event_id(tuple[:id])
            end

            super
          end
        end
      end
    end
  end
end
