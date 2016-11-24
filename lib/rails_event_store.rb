require 'rails_event_store_active_record'
require 'rails_event_store/all'

# Use active record by default
RailsEventStore.event_repository = RailsEventStoreActiveRecord::EventRepository.new
