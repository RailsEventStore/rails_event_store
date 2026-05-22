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
    :projection_new_constructor,
    "RubyEventStore::Projection.new is deprecated and will be removed in the next major release.\n" \
      "Use Projection.init(initial_state) instead.",
  )

  Deprecations.register(
    :projection_multiple_scopes,
    "Passing multiple scopes to RubyEventStore::Projection#call is deprecated and will be removed in the next major release.\n" \
      "Use a single scope instead, e.g. call(event_store.read.stream(\"stream_name\")).",
  )

  Deprecations.register(
    :projection_old_api,
    "RubyEventStore::Projection from_stream/from_all_streams/init/when/run API is deprecated and will be removed in the next major release.\n" \
      "Use Projection.init(initial_state).on(EventClass) { |state, event| new_state }.call(scope) instead.",
  )
  Deprecations.deprecate_class_method(Projection, :from_stream, key: :projection_old_api)
  Deprecations.deprecate_class_method(Projection, :from_all_streams, key: :projection_old_api)
  Deprecations.deprecate(Projection, :init, key: :projection_old_api)
  Deprecations.deprecate(Projection, :when, key: :projection_old_api)
  Deprecations.deprecate(Projection, :run, key: :projection_old_api)

  Deprecations.register(
    :instrumentation_renamed,
    "Instrumentation event names *.rails_event_store are deprecated and will be removed in the next major release.\n" \
      "Use *.ruby_event_store instead.",
  )

  Deprecations.register(
    :instrumented_mapper_serialize_deprecated,
    "Instrumentation event names serialize.mapper.ruby_event_store and deserialize.mapper.ruby_event_store are deprecated and will be removed in the next major release.\n" \
      "Use event_to_record.mapper.ruby_event_store and record_to_event.mapper.ruby_event_store instead.\n" \
      "The domain_event: payload key in serialize.mapper.ruby_event_store has been renamed to event: in event_to_record.mapper.ruby_event_store.",
  )

  Deprecations.register(
    :specification_in_batches_of,
    "RubyEventStore::Specification#in_batches_of is deprecated and will be removed in the next major release.\n\n" \
      "Use #in_batches instead.",
  )
  Deprecations.deprecate(Specification, :in_batches_of, key: :specification_in_batches_of)

  Deprecations.register(
    :specification_of_types,
    "RubyEventStore::Specification#of_types is deprecated and will be removed in the next major release.\n\n" \
      "Use #of_type instead.",
  )
  Deprecations.deprecate(Specification, :of_types, key: :specification_of_types)
end
