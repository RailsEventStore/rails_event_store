# frozen_string_literal: true

module RubyEventStore
  module Browser
    GetStreamMetadata =
      Struct.new(:event_store, :stream_name, keyword_init: true) do
        def call
          return if stream_name.eql?(SERIALIZED_GLOBAL_STREAM_NAME) || Browser.reserved_stream?(stream_name)
          metadata = event_store.stream_metadata(stream_name)
          metadata unless metadata.empty?
        rescue StreamMetadataNotSupported
          nil
        end
      end
  end
end
