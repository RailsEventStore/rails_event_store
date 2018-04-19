module RubyEventStore
  module ROM
    module Relations
      class Events < ::ROM::Relation[:sql]
        schema(:event_store_events, as: :events, infer: true) do
          associations do
            has_many :stream_entries
          end
        end
  
        def by_pks(ids)
          where(id: ids)
        end
      end
    end
  end
end
