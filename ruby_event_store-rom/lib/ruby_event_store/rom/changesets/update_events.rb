# frozen_string_literal: true

module RubyEventStore
  module ROM
    module Changesets
      class UpdateEvents < ::ROM::Changeset::Update
        module Defaults
          def self.included(base)
            base.class_eval do
              relation :events

              map(&:to_h)
              map do
                rename_keys timestamp: :created_at
                map_value   :created_at, ->(time) { Time.iso8601(time).localtime }
                map_value   :valid_at,   ->(time) { Time.iso8601(time).localtime }
                accept_keys %i[event_id data metadata event_type created_at valid_at]
              end
            end
          end
        end

        include Defaults
      end
    end
  end
end
