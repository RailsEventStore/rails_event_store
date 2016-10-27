require 'active_support/core_ext/class/attribute_accessors'

module RailsEventStore
  class Repository
    cattr_reader :adapter

    def self.adapter=(adapter)
      case adapter.to_s
      when 'in_memory'
        @@adapter = ::RubyEventStore::InMemoryRepository
      when String
        require "rails_event_store_#{adapter}"
        @@adapter = "::RailsEventStore#{adapter.to_s.classify}::EventRepository".constantize.new
      else
        @@adapter = adapter
      end
    end
  end
end
