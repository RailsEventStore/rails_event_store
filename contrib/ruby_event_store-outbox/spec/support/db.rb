RSpec.configure do |config|
  config.around(:each, db: true) do |example|
    begin
      establish_database_connection
      begin
        ActiveRecord::Migration.drop_table("event_store_outbox")
        ActiveRecord::Migration.drop_table("event_store_outbox_locks")
      rescue ::ActiveRecord::StatementInvalid
      end
      m = Migrator.new(File.expand_path("../../lib/generators/ruby_event_store/outbox/templates", __dir__))
      m.run_migration("create_event_store_outbox")
      example.run
    end
  end
end
