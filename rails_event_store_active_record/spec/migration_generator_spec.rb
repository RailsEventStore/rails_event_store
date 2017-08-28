require 'spec_helper'
require 'pp'
require 'fakefs/safe'

module RailsEventStoreActiveRecord
  describe MigrationGenerator do
    specify do
      FakeFS.with_fresh do
        FakeFS::FileSystem.clone(File.expand_path('../../', __FILE__))
        stub_const("Rails::VERSION::STRING", "4.2.8")

        generator = MigrationGenerator.new
        allow(Time).to receive(:now).and_return(Time.new(2016,8,9,22,22,22))
        generator.create_migration

        expect(File.read("db/migrate/20160809222222_create_event_store_events.rb")).to match(/ActiveRecord::Migration$/)
      end
    end

    specify do
      FakeFS.with_fresh do
        FakeFS::FileSystem.clone(File.expand_path('../../', __FILE__))
        stub_const("Rails::VERSION::STRING", "5.0.0")

        generator = MigrationGenerator.new
        allow(Time).to receive(:now).and_return(Time.new(2016,8,9,22,22,22))
        generator.create_migration

        expect(File.read("db/migrate/20160809222222_create_event_store_events.rb")).to match(/ActiveRecord::Migration\[4\.2\]$/)
      end
    end
  end
end
