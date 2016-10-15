module RailsEventStore
  if defined?(RailsEventStoreActiveRecord)
    require 'rails_event_store_active_record'
    EventRepository = RailsEventStoreActiveRecord::EventRepository
  end

  if defined?(RailsEventStoreMongoid)
    require 'rails_event_store_mongoid'
    EventRepository = RailsEventStoreMongoid::EventRepository
  end
end
