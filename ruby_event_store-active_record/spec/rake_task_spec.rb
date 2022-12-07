require "spec_helper"
require_relative "../../support/helpers/silence_stdout"
require "rake"

module RailsEventStore
  RSpec.describe "migration_tasks.rake" do
    before do
      allow(Time).to receive(:now).and_return(Time.new(2022, 11, 30, 21, 37, 00))
      load File.join(File.expand_path("../../lib/ruby_event_store/active_record/tasks", __FILE__) + "/migration_tasks.rake")
      Rake::Task["db:migrations:copy"].reenable
    end

    context "when custom path provided" do
      it "is created" do
        dir = Dir.mktmpdir(nil, "./")

        SilenceStdout.silence_stdout do
          ENV["DATA_TYPE"] = "jsonb"
          ENV["MIGRATION_PATH"] = dir
          Rake::Task["db:migrations:copy"].invoke
        end

        expect(File.exists?(File.join(File.expand_path("../../", __FILE__) + "#{dir[1..-1]}/20221130213700_create_event_store_events.rb")))
          .to be_truthy

      ensure
        FileUtils.rm_r(dir)
        ENV.delete("MIGRATION_PATH")
        ENV.delete("DATA_TYPE")
      end
    end

    context "when no path provided" do
      it "is created" do
        dir = FileUtils.mkdir_p("./db/migrate").first

        SilenceStdout.silence_stdout do
          ENV["DATA_TYPE"] = "jsonb"
          Rake::Task["db:migrations:copy"].invoke
        end

        expect(File.exists?(File.join(File.expand_path("../../", __FILE__) + "/db/migrate/20221130213700_create_event_store_events.rb")))
          .to be_truthy

      ensure
        FileUtils.rm_rf(dir)
        FileUtils.rmdir("./db")
        ENV.delete("DATA_TYPE")
      end
    end
  end
end
