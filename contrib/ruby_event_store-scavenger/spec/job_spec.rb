# frozen_string_literal: true

require "spec_helper"

module RubyEventStore
  module Scavenger
    ::RSpec.describe Job do
      let(:repository) { ActiveRecord::EventRepository.new(serializer: SpecHelper.serializer) }
      let(:client) { Client.new(repository: StreamMetadataAwareRepository.new(repository)) }

      before do
        client.publish(Array.new(3) { RubyEventStore::Event.new }, stream_name: "a", expected_version: :auto)
        client.set_stream_metadata("a", max_count: 1)
      end

      around do |example|
        ENV["RES_SCAVENGER"] = "1"
        example.run
      ensure
        ENV.delete("RES_SCAVENGER")
      end

      specify "is an ActiveJob" do
        expect(Job.ancestors).to include(::ActiveJob::Base)
      end

      specify "a dry run by default" do
        report = Job.perform_now

        expect(report.dry_run).to be(true)
        expect(report.marked).to eq(2)
        expect(client.read.stream("a").count).to eq(3)
      end

      specify "executes" do
        report = Job.perform_now(execute: true)

        expect(report.dry_run).to be(false)
        expect(client.read.stream("a").count).to eq(1)
      end

      specify "passes options to the runner" do
        allow(Runner).to receive(:active_record).and_call_original

        Job.perform_now(serializer: "json", batch_size: 5, policy: "links_only")

        expect(Runner).to have_received(:active_record).with(serializer: ::JSON, batch_size: 5, policy: "links_only")
      end

      specify "purges with the confirmation, also through a queue" do
        options = {
          execute: true,
          serializer: SpecHelper.serializer_name,
          policy: "purge",
          confirm: Runner::PURGE_CONFIRMATION,
          grace_period: 0,
          force: true,
        }

        expect(Job.execute(Job.new(**options).serialize).purged).to eq(2)
        expect(client.read.of_type(RubyEventStore::Event).count).to eq(1)
        expect { Job.perform_now(execute: true, policy: "purge") }.to raise_error(PurgeNotConfirmed)
      end

      specify "yaml serializer by default" do
        allow(Runner).to receive(:active_record).and_call_original

        Job.perform_now

        expect(Runner).to have_received(:active_record).with(serializer: Serializers::YAML)
      end

      specify "needs RES_SCAVENGER" do
        ENV.delete("RES_SCAVENGER")

        expect { Job.perform_now }.to raise_error(NotAllowed)
      end
    end
  end
end
