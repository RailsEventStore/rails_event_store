require 'spec_helper'
require 'pp'
require 'fakefs'

module RailsEventStoreActiveRecord
  describe MigrationGenerator do
    specify do
      FakeFS do
        FakeFS::FileSystem.clone(File.expand_path('../../', __FILE__))

        generator = MigrationGenerator.new
        allow(Time).to receive(:now).and_return(Time.new(2016,8,9,22,22,22))
        generator.create_migration

        expect(File.read("db/migrate/20160809222222_create_event_store_events.rb")).to match("ActiveRecord::Migration")
      end
    end
  end
end
