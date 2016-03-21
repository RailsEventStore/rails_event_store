require 'ruby_event_store'

module RailsEventStore
  Event               = RubyEventStore::Event
  InMemoryRepository  = RubyEventStore::InMemoryRepository
  EventBroker         = RubyEventStore::PubSub::Broker
end

require 'rails_event_store/models/event'
require 'rails_event_store/generators/migrate_generator'
require 'rails_event_store/generators/templates/migration_template'
require 'rails_event_store/version'
require 'rails_event_store/repositories/event_repository'
require 'rails_event_store/event_handlers/slack_event_handler'
require 'rails_event_store/errors'
require 'rails_event_store/client'
require 'rails_event_store/constants'
