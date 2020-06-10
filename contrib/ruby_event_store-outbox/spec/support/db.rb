
RSpec.configure do |config|
  config.around(:each, db: true) do |example|
    begin
      establish_database_connection
      # load_database_schema
      m = Migrator.new(File.expand_path('../../lib/generators/ruby_event_store/outbox/templates', __dir__))
      m.run_migration('create_event_store_outbox')
      example.run
    ensure
      # drop_database
      begin
        ActiveRecord::Migration.drop_table("event_store_outbox")
      rescue ActiveRecord::StatementInvalid
      end
    end
  end
end
