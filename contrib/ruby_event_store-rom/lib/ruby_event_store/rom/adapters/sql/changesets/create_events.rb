# frozen_string_literal: true

module RubyEventStore
  module ROM
    module SQL
      module Changesets
        class CreateEvents < ROM::Changesets::CreateEvents
          def commit
            relation.multi_insert(to_a)
          end
        end
      end
    end
  end
end
