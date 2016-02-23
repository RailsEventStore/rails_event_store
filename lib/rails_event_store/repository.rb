require 'active_support/core_ext/class/attribute_accessors'

module RailsEventStore
  class Repository

    cattr_reader :backend

    def self.backend=(backend)
      case backend
      when String, Symbol
        require "rails_event_store/repositories/#{backend}/event_repository"
        @@backend = "::RailsEventStore::Repositories::#{backend.to_s.classify}::EventRepository".constantize.new
      else
        @@bakend = backend
      end
    end

  end
end
