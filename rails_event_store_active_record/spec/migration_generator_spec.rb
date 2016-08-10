require 'spec_helper'

module RailsEventStoreActiveRecord
  describe MigrationGenerator do
    specify do
      generator = MigrationGenerator.new
      expect(Time).to receive(:now).and_return(Time.new(2016,8,9,22,22,22))
      expect(generator).to receive(:template).with(
        "migration_template.rb", "db/migrate/20160809222222_create_event_store_events.rb")
      generator.create_migration
    end
  end
end
