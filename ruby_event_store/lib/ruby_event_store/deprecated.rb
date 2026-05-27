# frozen_string_literal: true

module RubyEventStore
  Deprecations.register(
    :any_version_with_specific_position,
    "Mixing expected version :any and specific position (or :auto) is deprecated and will raise UnsupportedVersionAnyUsage in RubyEventStore 3.0.",
  )

  Deprecations.register(
    :instrumented_mapper_serialize_deprecated,
    "Instrumentation event names serialize.mapper.ruby_event_store and deserialize.mapper.ruby_event_store are deprecated and will be removed in the next major release.\n" \
      "Use event_to_record.mapper.ruby_event_store and record_to_event.mapper.ruby_event_store instead.\n" \
      "The domain_event: payload key in serialize.mapper.ruby_event_store has been renamed to event: in event_to_record.mapper.ruby_event_store.",
  )

end
