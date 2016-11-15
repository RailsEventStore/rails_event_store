require 'active_support/core_ext/class/attribute_accessors'

module RailsEventStore
  class Repository
    cattr_reader :adapter

    def self.adapter=(adapter)
      raise ArgumentError unless adapter
      @@adapter = adapter
    end
  end
end
