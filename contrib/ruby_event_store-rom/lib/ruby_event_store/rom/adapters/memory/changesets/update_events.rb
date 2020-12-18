# frozen_string_literal: true

module RubyEventStore
  module ROM
    module Memory
      module Changesets
        class UpdateEvents < ROM::Changesets::UpdateEvents
          def commit
            to_a.each do |params|
              attributes = command.input[params].to_h.delete_if { |k, v| k == :created_at }
              relation.by_event_id(params.fetch(:event_id)).dataset.map { |tuple| tuple.update(attributes) }
            end
          end
        end
      end
    end
  end
end
