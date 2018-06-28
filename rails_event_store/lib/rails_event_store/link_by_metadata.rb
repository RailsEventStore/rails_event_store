module RailsEventStore
  class LinkByMetadata < RubyEventStore::LinkByMetadata
    def initialize(event_store: Rails.configuration.event_store, **conf)
      super(event_store: event_store, **conf)
    end
  end
end