require 'spec_helper'
require 'pp'
require 'fakefs/safe'

module RailsEventStoreActiveRecord
  RSpec.describe MigrationGenerator do
    around(:each) do |example|
      current_stdout = $stdout
      $stdout = StringIO.new
      example.call
      $stdout = current_stdout
    end

    specify do
      FakeFS.with_fresh do
        FakeFS::FileSystem.clone(File.expand_path('../../', __FILE__))
        stub_const('Rails::VERSION::STRING', '4.2.8')

        generator = MigrationGenerator.new
        allow(Time).to receive(:now).and_return(Time.new(2016,8,9,22,22,22))
        generator.create_migration

        expect(File.read('db/migrate/20160809222222_create_event_store_events.rb')).to match(/ActiveRecord::Migration$/)
      end
    end

    specify do
      FakeFS.with_fresh do
        FakeFS::FileSystem.clone(File.expand_path('../../', __FILE__))

        rails_version = '5.2.0'
        rails_version_with_subnumber = rails_version.match(/\d\.\d/)[0]

        stub_const('Rails::VERSION::STRING', rails_version)

        generator = MigrationGenerator.new
        allow(Time).to receive(:now).and_return(Time.new(2016,8,9,22,22,22))
        generator.create_migration

        expect(File.read('db/migrate/20160809222222_create_event_store_events.rb')).to include("ActiveRecord::Migration[#{rails_version_with_subnumber}]")
      end
    end
  end
end
