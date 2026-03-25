# frozen_string_literal: true

require_relative "../spec_helper"
require "ruby_event_store/cli/commands/stream_delete"

module RubyEventStore
  module CLI
    module Commands
      RSpec.describe StreamDelete do
        let(:event_store) { RubyEventStore::Client.new }
        let(:command) { StreamDelete.new }

        before { EventStoreResolver.event_store = event_store }

        describe "#call" do
          it "deletes the stream with --force" do
            event_store.publish(RubyEventStore::Event.new, stream_name: "to-delete")

            begin
              command.call(stream_name: "to-delete", dry_run: false, force: true)
            rescue SystemExit
            end

            expect(event_store.read.stream("to-delete").count).to eq(0)
          end

          it "prints confirmation after deletion" do
            event_store.publish(RubyEventStore::Event.new, stream_name: "to-delete")

            expect {
              begin
                command.call(stream_name: "to-delete", dry_run: false, force: true)
              rescue SystemExit
              end
            }.to output(/Deleted stream 'to-delete'/).to_stdout
          end

          it "shows what would be deleted in dry-run mode" do
            event_store.publish(RubyEventStore::Event.new, stream_name: "to-delete")

            expect {
              begin
                command.call(stream_name: "to-delete", dry_run: true, force: false)
              rescue SystemExit
              end
            }.to output(/Would delete stream 'to-delete'/).to_stdout

            expect(event_store.read.stream("to-delete").count).to eq(1)
          end

          it "does not delete in dry-run mode" do
            event_store.publish(RubyEventStore::Event.new, stream_name: "to-delete")

            begin
              command.call(stream_name: "to-delete", dry_run: true, force: false)
            rescue SystemExit
            end

            expect(event_store.read.stream("to-delete").count).to eq(1)
          end

          it "prints error for empty or non-existent stream" do
            expect {
              begin
                command.call(stream_name: "non-existent", dry_run: false, force: true)
              rescue SystemExit
              end
            }.to output(/non-existent/).to_stderr
          end

          it "prompts for confirmation without --force" do
            event_store.publish(RubyEventStore::Event.new, stream_name: "to-delete")
            allow($stdin).to receive(:gets).and_return("y\n")

            begin
              command.call(stream_name: "to-delete", dry_run: false, force: false)
            rescue SystemExit
            end

            expect(event_store.read.stream("to-delete").count).to eq(0)
          end

          it "aborts when confirmation is declined" do
            event_store.publish(RubyEventStore::Event.new, stream_name: "to-delete")
            allow($stdin).to receive(:gets).and_return("n\n")

            expect {
              begin
                command.call(stream_name: "to-delete", dry_run: false, force: false)
              rescue SystemExit
              end
            }.to output(/Aborted/).to_stdout

            expect(event_store.read.stream("to-delete").count).to eq(1)
          end

          context "with --prefix" do
            before do
              allow(command).to receive(:fetch_streams_with_prefix).with("test-").and_return(["test-1", "test-2"])
              allow(command).to receive(:fetch_streams_with_prefix).with("empty-").and_return([])
            end

            it "deletes all matching streams with --force" do
              event_store.publish(RubyEventStore::Event.new, stream_name: "test-1")
              event_store.publish(RubyEventStore::Event.new, stream_name: "test-2")

              begin
                command.call(prefix: "test-", dry_run: false, force: true)
              rescue SystemExit
              end

              expect(event_store.read.stream("test-1").count).to eq(0)
              expect(event_store.read.stream("test-2").count).to eq(0)
            end

            it "prints deletion confirmation for each stream" do
              event_store.publish(RubyEventStore::Event.new, stream_name: "test-1")
              event_store.publish(RubyEventStore::Event.new, stream_name: "test-2")

              expect {
                begin
                  command.call(prefix: "test-", dry_run: false, force: true)
                rescue SystemExit
                end
              }.to output(/Deleted 'test-1'/).to_stdout
            end

            it "prints total deletion count" do
              event_store.publish(RubyEventStore::Event.new, stream_name: "test-1")
              event_store.publish(RubyEventStore::Event.new, stream_name: "test-2")

              expect {
                begin
                  command.call(prefix: "test-", dry_run: false, force: true)
                rescue SystemExit
                end
              }.to output(/Deleted 2 stream\(s\)/).to_stdout
            end

            it "shows what would be deleted in dry-run mode" do
              expect {
                begin
                  command.call(prefix: "test-", dry_run: true, force: false)
                rescue SystemExit
                end
              }.to output(/Would delete 2 stream\(s\)/).to_stdout
            end

            it "requires --force for bulk deletion" do
              expect {
                begin
                  command.call(prefix: "test-", dry_run: false, force: false)
                rescue SystemExit
                end
              }.to output(/--force is required/).to_stderr
            end

            it "rejects empty prefix" do
              expect {
                begin
                  command.call(prefix: "", dry_run: false, force: true)
                rescue SystemExit
                end
              }.to output(/Prefix cannot be empty/).to_stderr
            end

            it "prints error when no streams match prefix" do
              expect {
                begin
                  command.call(prefix: "empty-", dry_run: false, force: true)
                rescue SystemExit
                end
              }.to output(/No streams found/).to_stderr
            end
          end
        end
      end
    end
  end
end
