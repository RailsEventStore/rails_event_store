# frozen_string_literal: true

def drop_tables
  ActiveRecord::Migration.drop_table("event_store_outbox")
  ActiveRecord::Migration.drop_table("event_store_outbox_locks")
rescue ::ActiveRecord::StatementInvalid
end

RSpec.configure do |config|
  config.around(:each, :db) do |example|
    begin
      establish_database_connection
      drop_tables
      m = Migrator.new(File.expand_path("../../lib/generators/ruby_event_store/outbox/templates", __dir__))
      m.run_migration("create_event_store_outbox")
      example.run
    ensure
      drop_tables
      close_database_connection
    end
  end
end
