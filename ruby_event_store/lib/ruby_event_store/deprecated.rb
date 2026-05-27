# frozen_string_literal: true

module RubyEventStore
  Deprecations.register(
    :dispatcher_renamed,
    "`RubyEventStore::Dispatcher` is deprecated and will be removed in the next major release.\n" \
      "Use `RubyEventStore::SyncScheduler` instead.",
  )
  Deprecations.deprecate(Dispatcher, :initialize, key: :dispatcher_renamed)

  Deprecations.register(
    :immediate_async_dispatcher_renamed,
    "`RubyEventStore::ImmediateAsyncDispatcher` is deprecated and will be removed in the next major release.\n" \
      "Use `RubyEventStore::ImmediateDispatcher` instead.",
  )
  Deprecations.deprecate(ImmediateAsyncDispatcher, :initialize, key: :immediate_async_dispatcher_renamed)

  Deprecations.register(
    :class_subscriber,
    "Passing a class as a subscriber is deprecated and will be removed in the next major release.\n" \
      "Pass an instance or lambda instead, e.g. subscribe(MyHandler.new, to: [MyEvent]).",
  )

  Deprecations.register(
    :null_mapper,
    "`RubyEventStore::Mappers::NullMapper` is deprecated and will be removed in the next major release.\n" \
      "Use `RubyEventStore::Mappers::Default.new` instead.",
  )
  Deprecations.deprecate(Mappers::NullMapper, :initialize, key: :null_mapper)

  Deprecations.register(
    :events_class_remapping_option,
    "`events_class_remapping` option in `RubyEventStore::Mappers::Default` is deprecated and will be removed in the next major release.\n" \
      "Use `RubyEventStore::Mappers::Transformation::Upcast` instead.",
  )

  Deprecations.register(
    :event_class_remapper,
    "`RubyEventStore::Mappers::Transformation::EventClassRemapper` is deprecated and will be removed in the next major release.\n" \
      "Use `RubyEventStore::Mappers::Transformation::Upcast` instead.",
  )
  Deprecations.deprecate(Mappers::Transformation::EventClassRemapper, :initialize, key: :event_class_remapper)

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
