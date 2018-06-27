module RubyEventStore
  class LinkByMetadata

    def initialize(
      event_store:,
      key:,
      prefix: ["$by", key, nil].join("_")
    )
      @event_store = event_store
      @key = key
      @prefix = prefix
    end

    def call(event)
      return unless event.metadata.has_key?(@key)

      @event_store.link_to_stream(
        [event.message_id],
        stream_name: "#{@prefix}#{event.metadata.fetch(@key)}"
      )
    end

  end
end