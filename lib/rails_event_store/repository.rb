require 'active_support/core_ext/class/attribute_accessors'

module RailsEventStore
  class Repository

    cattr_reader :backend

    def self.backend=(backend)
      require "rails_event_store/repositories/#{backend}"
      @@backend = "::RailsEventStore::Repositories::#{backend.to_s.classify}::EventRepository".constantize.new
    end

  end
end
