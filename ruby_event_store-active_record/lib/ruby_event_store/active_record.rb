# frozen_string_literal: true

require_relative "active_record/generators/migration_generator"
require_relative "active_record/generators/rails_migration_generator"
require_relative "active_record/pass_through"
require_relative "active_record/event"
require_relative "active_record/with_default_models"
require_relative "active_record/with_abstract_base_class"
require_relative "active_record/event_repository"
require_relative "active_record/batch_enumerator"
require_relative "active_record/event_repository_reader"
require_relative "active_record/index_violation_detector"
require_relative "active_record/pg_linearized_event_repository"
require_relative "active_record/version"
require_relative "active_record/railtie" if defined?(Rails::Engine)
