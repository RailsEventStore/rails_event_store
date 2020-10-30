require 'spec_helper'
require 'pp'
require 'fakefs/safe'

module RailsEventStoreActiveRecord
  RSpec.describe NoGlobalStreamEntriesGenerator do
    around(:each) do |example|
      current_stdout = $stdout
      $stdout = StringIO.new
      example.call
      $stdout = current_stdout
    end

    specify do
      FakeFS.with_fresh do
        FakeFS::FileSystem.clone(File.expand_path('../../', __FILE__))
        stub_const("Rails::VERSION::STRING", "4.2.8")

        generator = NoGlobalStreamEntriesGenerator.new
        allow(Time).to receive(:now).and_return(Time.new(2016,8,9,22,22,22))
        generator.create_migration

        expect(File.read("db/migrate/20160809222222_no_global_stream_entries.rb")).to match(/ActiveRecord::Migration$/)
      end
    end

    specify do
      FakeFS.with_fresh do
        FakeFS::FileSystem.clone(File.expand_path('../../', __FILE__))
        stub_const("Rails::VERSION::STRING", "5.0.0")

        generator = NoGlobalStreamEntriesGenerator.new
        allow(Time).to receive(:now).and_return(Time.new(2016,8,9,22,22,22))
        generator.create_migration

        expect(File.read("db/migrate/20160809222222_no_global_stream_entries.rb")).to match(/ActiveRecord::Migration\[4\.2\]$/)
      end
    end
  end
end
