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

    around do |example|
      FakeFS.with_fresh do
        FakeFS::FileSystem.clone(File.expand_path('../../', __FILE__))
        example.run
      end
    end

    before do
      allow(Time).to receive(:now).and_return(
        Time.new(2016, 8, 9, 22, 22, 22)
      )
    end

    subject do
      generator = MigrationGenerator.new
      generator.create_migration
      File.read('db/migrate/20160809222222_create_event_store_events.rb')
    end

    context 'with Rails 4' do
      before do
        stub_const('Rails::VERSION::STRING', '4.2.8')
      end

      it { is_expected.to match(/ActiveRecord::Migration$/) }
    end

    context 'with Rails 5' do
      before do
        stub_const('Rails::VERSION::STRING', '5.0.0')
      end

      it { is_expected.to match(/ActiveRecord::Migration\[4\.2\]$/) }
    end
  end
end
