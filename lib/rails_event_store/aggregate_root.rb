module RailsEventStore
  module AggregateRoot
    def generate_uuid
      SecureRandom.uuid
    end
  end
end
