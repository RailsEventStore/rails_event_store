# frozen_string_literal: true

module RubyEventStore
  module CLI
    class ReadEvents
      def self.of(specification, type: nil, after: nil, before: nil, from: nil, limit:)
        specification = specification.of_type(resolve_type(type))    if type
        specification = specification.newer_than(Time.parse(after))  if after
        specification = specification.older_than(Time.parse(before)) if before
        specification = specification.from(from)                     if from
        specification.limit(limit.to_i).to_a
      end

      def self.resolve_type(name)
        Object.const_get(name)
      rescue NameError
        raise "Unknown event type: #{name}"
      end
    end
  end
end
