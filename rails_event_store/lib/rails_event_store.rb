require 'active_support/core_ext/class/attribute_accessors'
require 'rails_event_store_active_record'
require 'rails_event_store/all'

module RailsEventStore
  mattr_reader :event_repository

  def self.event_repository=(event_repository)
    raise ArgumentError unless event_repository
    @@event_repository = event_repository
  end
end

# Use active record by default
RailsEventStore.event_repository = RailsEventStoreActiveRecord::EventRepository.new
