module RailsEventStore

  class LinkByMetadata < RubyEventStore::LinkByMetadata
    def initialize(event_store: Rails.configuration.event_store, key:, prefix: nil)
      super(event_store: event_store, key: key, prefix: prefix)
    end
  end

  class LinkByCorrelationId < RubyEventStore::LinkByCorrelationId
    def initialize(event_store: Rails.configuration.event_store, prefix: nil)
      super(event_store: event_store, prefix: prefix)
    end
  end

  class LinkByCausationId < RubyEventStore::LinkByCausationId
    def initialize(event_store: Rails.configuration.event_store, prefix: nil)
      super(event_store: event_store, prefix: prefix)
    end
  end

end