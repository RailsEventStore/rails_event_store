require 'active_support/inflector'

require 'rails_event_store/version'
require 'rails_event_store/repository'
require 'rails_event_store/event'
require 'rails_event_store/repositories/aggregate_repository'
require 'rails_event_store/event_handlers/slack_event_handler'
require 'rails_event_store/aggregate_root'
require 'rails_event_store/errors'
require 'rails_event_store/client'
require 'rails_event_store/constants'

# Default, should be done in respective backend gem
RailsEventStore::Repository.backend = :active_record

if defined?(ActiveRecord)
  require 'rails_event_store/generators/migrate_generator'
  require 'rails_event_store/generators/templates/migration_template'
end
