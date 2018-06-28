module RubyEventStore
  class LinkByMetadata

    def initialize(
      event_store:,
      key:,
      prefix: nil
    )
      @event_store = event_store
      @key = key
      @prefix = prefix || ["$by", key, nil].join("_")
    end

    def call(event)
      return unless event.metadata.has_key?(@key)

      @event_store.link_to_stream(
        [event.message_id],
        stream_name: "#{@prefix}#{event.metadata.fetch(@key)}"
      )
    end

  end

  class LinkByCorrelationId < LinkByMetadata
    def initialize(event_store:, prefix: nil)
      super(
        event_store: event_store,
        prefix:      prefix,
        key:         :correlation_id,
      )
    end
  end

  class LinkByCausationId < LinkByMetadata
    def initialize(event_store:, prefix: nil)
      super(
        event_store: event_store,
        prefix:      prefix,
        key:         :causation_id,
      )
    end
  end
end