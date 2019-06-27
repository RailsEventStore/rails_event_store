# frozen_string_literal: true

module RailsEventStore

  class LinkByMetadata < RubyEventStore::LinkByMetadata
    def initialize(event_store: Rails.configuration.event_store, key:, prefix: nil)
      super
    end
  end

  class LinkByCorrelationId < RubyEventStore::LinkByCorrelationId
    def initialize(event_store: Rails.configuration.event_store, prefix: nil)
      super
    end
  end

  class LinkByCausationId < RubyEventStore::LinkByCausationId
    def initialize(event_store: Rails.configuration.event_store, prefix: nil)
      super
    end
  end

  class LinkByEventType < RubyEventStore::LinkByEventType
    def initialize(event_store: Rails.configuration.event_store, prefix: nil)
      super
    end
  end

end
