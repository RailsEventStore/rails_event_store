$LOAD_PATH.unshift File.expand_path('../../lib', __FILE__)
require 'rails_event_store_active_record'

ENV['DATABASE_URL'] ||= "postgres://localhost/rails_event_store_active_record?pool=5"

MigrationCode = File.read(File.expand_path('../../lib/rails_event_store_active_record/generators/templates/migration_template.rb', __FILE__) )
migration_version = Gem::Version.new(ActiveRecord::VERSION::STRING) < Gem::Version.new("5.0.0") ? "" : "[4.2]"
MigrationCode.gsub!("<%= migration_version %>", migration_version)
MigrationCode.gsub!("force: false", "force: true")

RSpec.configure do |config|
  config.failure_color = :magenta
end
