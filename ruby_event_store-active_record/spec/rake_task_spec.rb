require "spec_helper"
require_relative "../../support/helpers/silence_stdout"
require "rake"

module RailsEventStore
  RSpec.describe Rake do
    before do
      allow(Time).to receive(:now).and_return(Time.new(2022, 11, 30, 21, 37, 00))
      load File.expand_path(File.expand_path("../../", __FILE__) + "/Rakefile")
      Rake::Task["g:migration"].reenable
    end

    context "when custom path provided" do
      it "is created" do
        dir = Dir.mktmpdir(nil, "./")

        SilenceStdout.silence_stdout do
          Rake::Task["g:migration"].invoke("jsonb", "#{dir}/")
        end

        expect(File.exists?(File.expand_path(File.expand_path("../../", __FILE__) + "#{dir[1..-1]}/20221130213700_create_event_store_events.rb")))
          .to be_truthy

      ensure
        FileUtils.rm_r(dir)
      end
    end

    context "when no path provided" do
      it "is created" do
        dir = FileUtils.mkdir_p("./db/migrate").first

        SilenceStdout.silence_stdout do
          Rake::Task["g:migration"].invoke("jsonb")
        end

        expect(File.exists?(File.expand_path(File.expand_path("../../", __FILE__) + "/db/migrate/20221130213700_create_event_store_events.rb")))
          .to be_truthy

      ensure
        FileUtils.rm_rf(dir)
        FileUtils.rmdir("./db")
      end
    end
  end
end
