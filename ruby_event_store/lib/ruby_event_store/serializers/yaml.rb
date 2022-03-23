# frozen_string_literal: true

require "yaml"

module RubyEventStore
  module Serializers
    class YAML
      def self.dump(value)
        ::YAML.dump(value)
      end

      def self.load(serialized)
        if ::YAML.respond_to?(:unsafe_load)
          ::YAML.unsafe_load(serialized)
        else
          ::YAML.load(serialized)
        end
      end
    end
  end
end