# frozen_string_literal: true

module RubyEventStore
  module Scavenger
    InvalidPolicy = Class.new(Error)

    # What the scavenger removes physically once an entry has been hidden long enough.
    #
    # :links_only - the links of hidden entries to their stream; the events stay in the global
    #               stream, so global positions have no gaps
    # :purge      - the links, as :links_only, and then every event of a removed link that no
    #               stream links to any more; LEAVES GAPS IN GLOBAL POSITIONS
    class Policy < Data.define(:name)
      NAMES = %i[links_only purge].freeze

      def self.links_only
        new(name: :links_only)
      end

      def self.purge
        new(name: :purge)
      end

      # @param value [Policy, Symbol, String]
      # @return [Policy]
      # @raise [InvalidPolicy] when the scavenger has no such policy
      def self.of(value)
        return value if value.instance_of?(Policy)
        name = NAMES.find { |known| known.name.eql?(value.to_s) }
        raise InvalidPolicy, "Unknown scavenger policy: #{value.inspect}" if name.nil?
        new(name: name)
      end

      def initialize(name:)
        raise InvalidPolicy, "Unknown scavenger policy: #{name.inspect}" unless NAMES.include?(name)
        super
      end

      def purge?
        name.equal?(:purge)
      end

      def to_s
        name.to_s
      end
    end
  end
end
