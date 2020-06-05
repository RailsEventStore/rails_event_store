require 'spec_helper'
require 'ruby_event_store/spec/scheduler_lint'

module RubyEventStore
  module Outbox
    RSpec.describe SidekiqScheduler do
      it_behaves_like :scheduler, SidekiqScheduler.new

      describe "#verify" do
        specify do
          correct_handler = Class.new do
            def self.through_outbox?
              true
            end
          end

          expect(subject.verify(correct_handler)).to eq(true)
        end

        specify do
          handler_with_falsey_method = Class.new do
            def self.through_outbox?
              false
            end
          end

          expect(subject.verify(handler_with_falsey_method)).to eq(false)
        end

        specify do
          handler_without_method = Class.new do
          end

          expect(subject.verify(handler_without_method)).to eq(false)
        end

        specify do
          object_responding_but_not_a_class = OpenStruct.new(through_outbox?: true)

          expect(subject.verify(object_responding_but_not_a_class)).to eq(false)
        end
      end

      describe "#call" do
        include SchemaHelper

        around(:each) do |example|
          begin
            establish_database_connection
            # load_database_schema
            m = Migrator.new(File.expand_path('../lib/generators/templates', __dir__))
            m.run_migration('create_event_store_outbox')
            example.run
          ensure
            # drop_database
            ActiveRecord::Migration.drop_table("event_store_outbox")
          end
        end

        specify do
          event = TimestampEnrichment.with_timestamp(Event.new(event_id: "83c3187f-84f6-4da7-8206-73af5aca7cc8"), Time.utc(2019, 9, 30))
          serialized_event = RubyEventStore::Mappers::Default.new.event_to_serialized_record(event)
          class ::CorrectAsyncHandler
            include Sidekiq::Worker
            sidekiq_options queue: 'default'
            def through_outbox?; true; end
          end

          subject.call(CorrectAsyncHandler, serialized_event)

          expect(Record.count).to eq(1)
          record = Record.first
          expect(record.created_at).to be_present
          expect(record.enqueued_at).to be_nil
          expect(record.split_key).to eq('default')
          expect(record.format).to eq('sidekiq5')
          expect(JSON.parse(record.payload).deep_symbolize_keys).to match({
            class: "CorrectAsyncHandler",
            queue: "default",
            created_at: be_present,
            jid: be_present,
            retry: true,
            args: [{
              event_id: "83c3187f-84f6-4da7-8206-73af5aca7cc8",
              event_type: "RubyEventStore::Event",
              data: "--- {}\n",
              metadata: "---\n:timestamp: 2019-09-30 00:00:00.000000000 Z\n",
            }]
          })
        end

        specify "custom queue name is taken into account" do
          event = TimestampEnrichment.with_timestamp(Event.new(event_id: "83c3187f-84f6-4da7-8206-73af5aca7cc8"), Time.utc(2019, 9, 30))
          serialized_event = RubyEventStore::Mappers::Default.new.event_to_serialized_record(event)
          class ::CorrectAsyncHandler
            include Sidekiq::Worker
            sidekiq_options queue: 'custom_queue'
            def through_outbox?; true; end
          end

          subject.call(CorrectAsyncHandler, serialized_event)

          record = Record.first
          expect(record.split_key).to eq('custom_queue')
          expect(JSON.parse(record.payload).deep_symbolize_keys[:queue]).to eq("custom_queue")
        end
      end
    end
  end
end
