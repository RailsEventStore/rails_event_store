require "spec_helper"
require_relative "../../support/helpers/silence_stdout"
require "rake"

module RailsEventStore
  RSpec.describe Rake do
    around do |example|
      begin
        @dir = Dir.mktmpdir(nil, "./")
        example.call
      ensure
        FileUtils.rm_r(@dir)
      end
    end

    before do
      allow(Time).to receive(:now).and_return(Time.new(2022, 11, 30, 21, 37, 00))
      load File.expand_path(File.expand_path("../../", __FILE__) + "/Rakefile")
    end

    context "when custom path provided" do
      it "is created" do
        SilenceStdout.silence_stdout do
          Rake::Task["g:migration"].invoke("jsonb", "#{@dir}/")
        end
        File.read(File.expand_path(File.expand_path("../../", __FILE__) + "#{@dir[1..-1]}/20221130213700_create_event_store_events.rb"))
      end
    end
  end
end
