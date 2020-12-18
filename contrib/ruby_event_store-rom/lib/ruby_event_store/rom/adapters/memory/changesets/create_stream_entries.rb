# frozen_string_literal: true

module RubyEventStore
  module ROM
    module Memory
      module Changesets
        class CreateStreamEntries < ROM::Changesets::CreateStreamEntries
          def commit
            to_a.each do |tuple|
              relation.send(:verify_uniquness!, tuple)
            end

            super
          end
        end
      end
    end
  end
end
