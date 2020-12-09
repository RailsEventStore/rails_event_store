require 'spec_helper'
require 'pp'
require 'fakefs/safe'

module RailsEventStoreActiveRecord
  RSpec.describe AddValidAtGenerator do
    around do |example|
      current_stdout = $stdout
      $stdout = StringIO.new
      example.call
      $stdout = current_stdout
    end

    around do |example|
      FakeFS.with_fresh do
        FakeFS::FileSystem.clone(File.expand_path('../../lib/rails_event_store_active_record/generators/templates', __FILE__))
        example.run
      end
    end

    specify do
      stub_const("Rails::VERSION::STRING", "4.2.8")

      generator = AddValidAtGenerator.new
      allow(Time).to receive(:now).and_return(Time.new(2016,8,9,22,22,22))
      generator.create_migration

      expect(File.read("db/migrate/20160809222222_add_valid_at.rb")).to match(/ActiveRecord::Migration$/)
    end

    specify do
      stub_const("Rails::VERSION::STRING", "5.0.0")

      generator = AddValidAtGenerator.new
      allow(Time).to receive(:now).and_return(Time.new(2016,8,9,22,22,22))
      generator.create_migration

      expect(File.read("db/migrate/20160809222222_add_valid_at.rb")).to match(/ActiveRecord::Migration\[4\.2\]$/)
    end
  end
end
