require "rails_event_store_active_record/legacy/version"
require "rails_event_store_active_record/legacy/event_repository"
require "rails_event_store_active_record/legacy/generators/v1_v2_migration_generator"

module RailsEventStoreActiveRecord
  LegacyEventRepository = Legacy::EventRepository
end
