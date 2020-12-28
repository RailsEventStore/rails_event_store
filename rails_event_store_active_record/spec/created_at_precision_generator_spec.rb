require 'spec_helper'
require 'pp'
require 'fakefs/safe'
require_relative '../../support/helpers/silence_stdout'


module RailsEventStoreActiveRecord
  RSpec.describe CreatedAtPrecisionGenerator do
    around do |example|
      SilenceStdout.silence_stdout { example.run }
    end

    around do |example|
      FakeFS.with_fresh do
        FakeFS::FileSystem.clone(File.expand_path('../../lib/rails_event_store_active_record/generators/templates', __FILE__))
        example.run
      end
    end

    specify do
      stub_const("Rails::VERSION::STRING", "4.2.8")

      generator = CreatedAtPrecisionGenerator.new
      allow(Time).to receive(:now).and_return(Time.new(2016,8,9,22,22,22))
      generator.create_migration

      expect(File.read("db/migrate/20160809222222_created_at_precision.rb")).to match(/ActiveRecord::Migration$/)
    end

    specify do
      stub_const("Rails::VERSION::STRING", "5.0.0")

      generator = CreatedAtPrecisionGenerator.new
      allow(Time).to receive(:now).and_return(Time.new(2016,8,9,22,22,22))
      generator.create_migration

      expect(File.read("db/migrate/20160809222222_created_at_precision.rb")).to match(/ActiveRecord::Migration\[4\.2\]$/)
    end
  end
end
