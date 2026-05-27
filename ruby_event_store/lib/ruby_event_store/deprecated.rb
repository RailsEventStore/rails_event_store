# frozen_string_literal: true

module RubyEventStore
  Deprecations.register(
    :any_version_with_specific_position,
    "Mixing expected version :any and specific position (or :auto) is deprecated and will raise UnsupportedVersionAnyUsage in RubyEventStore 3.0.",
  )

end
