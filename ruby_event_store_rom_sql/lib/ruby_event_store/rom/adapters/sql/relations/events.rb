module RubyEventStore
  module ROM
    module SQL
      module Relations
        class Events < ::ROM::Relation[:sql]
          schema(:event_store_events, as: :events, infer: true)
        end
      end
    end
  end
end
