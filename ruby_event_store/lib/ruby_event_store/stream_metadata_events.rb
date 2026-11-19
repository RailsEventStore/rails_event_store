# frozen_string_literal: true

module RubyEventStore
  # Events that record changes of stream metadata. Each one is appended to the meta stream of the
  # stream it describes (see StreamMetadata.meta_stream) and is the source of truth for that change.
  #
  # Data uses string keys, so it reads back the same with every serializer. Every event carries
  # "stream", the name of the stream it describes. Times (soft_deleted_at, tombstoned_at) are the
  # timestamp of the event itself.
  module StreamMetadataEvents
    # data: { "stream" => String, "max_count" => Integer | nil, "max_age" => Integer | nil }
    # Replaces both retention settings; nil clears one.
    StreamMetadataChanged = Class.new(Event)

    # data: { "stream" => String, "before_position" => Integer }
    # Hides the entries at positions below before_position. A boundary never moves back.
    StreamTruncated = Class.new(Event)

    # data: { "stream" => String }
    # Hides every entry the stream holds when the event is written.
    StreamSoftDeleted = Class.new(Event)

    # data: { "stream" => String }
    # Closes the stream for writes. The event is also linked into the stream as a hidden sentinel.
    StreamTombstoned = Class.new(Event)

    # data: { "stream" => String }
    # Clears soft delete and truncation, so the hidden entries become visible again.
    StreamRestored = Class.new(Event)

    # data: { "stream" => String, "policy" => String, "removed_links" => Integer, "removed_events" => Integer }
    # Written by the scavenger after it removed entries. Changes no metadata.
    StreamScavenged = Class.new(Event)
  end
end
