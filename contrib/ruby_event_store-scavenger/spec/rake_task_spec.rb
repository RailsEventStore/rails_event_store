# frozen_string_literal: true

require "spec_helper"
require "rake"

module RubyEventStore
  module Scavenger
    ::RSpec.describe "rake tasks" do
      before(:all) do
        Rake.application = Rake::Application.new
        load File.expand_path("../lib/ruby_event_store/scavenger/rake_task.rb", __dir__)
      end

      let(:repository) { ActiveRecord::EventRepository.new(serializer: SpecHelper.serializer) }
      let(:client) { Client.new(repository: StreamMetadataAwareRepository.new(repository)) }

      def invoke(name)
        task = Rake::Task[name]
        task.reenable
        task.invoke
      end

      def with_env(env)
        previous = env.keys.to_h { |key| [key, ENV[key]] }
        env.each { |key, value| ENV[key] = value }
        yield
      ensure
        previous.each { |key, value| value.nil? ? ENV.delete(key) : ENV[key] = value }
      end

      before do
        client.publish(Array.new(3) { RubyEventStore::Event.new }, stream_name: "a", expected_version: :auto)
        client.set_stream_metadata("a", max_count: 1)
      end

      specify "res:scavenge is a dry run by default" do
        expect { invoke("res:scavenge") }.to output(/\ADry run, nothing changed\./).to_stdout
        expect(client.read.stream("a").count).to eq(3)
      end

      specify "res:scavenge with EXECUTE=1" do
        with_env("EXECUTE" => "1") { expect { invoke("res:scavenge") }.to output(/\AScavenged\./).to_stdout }

        expect(client.read.stream("a").count).to eq(1)
      end

      specify "res:scavenge exits on an error" do
        with_env("GRACE_PERIOD" => "0") do
          expect { invoke("res:scavenge") }.to raise_error(SystemExit) { |error|
            expect(error.status).to eq(1)
          }.and output(/needs force/).to_stderr
        end
      end

      specify "res:scavenge:status" do
        expect { invoke("res:scavenge:status") }.to output(/\Astatus: idle/).to_stdout
      end

      specify "res:scavenge:migration" do
        Dir.mktmpdir do |dir|
          with_env("MIGRATION_PATH" => dir) do
            expect { invoke("res:scavenge:migration") }.to output(%r{\AMigration file created #{dir}/}).to_stdout
          end
          expect(Dir.children(dir)).to match([/_create_event_store_scavenger_state\.rb\z/])
        end
      end
    end
  end
end
