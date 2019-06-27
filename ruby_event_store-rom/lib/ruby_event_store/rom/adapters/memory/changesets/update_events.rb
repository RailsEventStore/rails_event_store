# frozen_string_literal: true

module RubyEventStore
  module ROM
    module Memory
      module Changesets
        class UpdateEvents < ROM::Changesets::UpdateEvents
          def commit
            to_a.each do |params|
              attributes = command.input[params].to_h.delete_if { |k, v| k == :created_at && v.nil? }
              relation.by_pk(params.fetch(:id)).dataset.map { |tuple| tuple.update(attributes) }
            end
          end
        end
      end
    end
  end
end
