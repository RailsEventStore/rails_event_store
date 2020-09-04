require 'spec_helper'
require 'ruby_event_store/spec/scheduler_lint'
require_relative './support/sidekiq'

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

      describe "#call", db: true do
        include SchemaHelper

        before(:each) do |example|
          reset_sidekiq_middlewares
        end

        specify do
          event = TimestampEnrichment.with_timestamp(Event.new(event_id: "83c3187f-84f6-4da7-8206-73af5aca7cc8"), Time.utc(2019, 9, 30))
          serialized_record = RubyEventStore::Mappers::Default.new.event_to_serialized_record(event)
          class ::CorrectAsyncHandler
            include Sidekiq::Worker
            def through_outbox?; true; end
          end

          subject.call(CorrectAsyncHandler, serialized_record)

          expect(Record.count).to eq(1)
          record = Record.first
          expect(record.created_at).to be_present
          expect(record.enqueued_at).to be_nil
          expect(record.split_key).to eq('default')
          expect(record.format).to eq('sidekiq5')
          expect(record.hash_payload).to match({
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
          serialized_record = RubyEventStore::Mappers::Default.new.event_to_serialized_record(event)
          class ::CorrectAsyncHandler
            include Sidekiq::Worker
            sidekiq_options queue: 'custom_queue'
            def through_outbox?; true; end
          end

          subject.call(CorrectAsyncHandler, serialized_record)

          record = Record.first
          expect(record.split_key).to eq('custom_queue')
          expect(record.hash_payload[:queue]).to eq("custom_queue")
        end

        specify "client middleware may abort scheduling" do
          event = TimestampEnrichment.with_timestamp(Event.new(event_id: "83c3187f-84f6-4da7-8206-73af5aca7cc8"), Time.utc(2019, 9, 30))
          serialized_record = RubyEventStore::Mappers::Default.new.event_to_serialized_record(event)
          class ::AlwaysCancellingMiddleware
            def call(_worker_class, _msg, _queue, _redis_pool)
            end
          end
          install_sidekiq_middleware(::AlwaysCancellingMiddleware)
          class ::CorrectAsyncHandler
            include Sidekiq::Worker
            def through_outbox?; true; end
          end

          subject.call(CorrectAsyncHandler, serialized_record)

          expect(Record.count).to eq(0)
        end
      end
    end
  end
end
