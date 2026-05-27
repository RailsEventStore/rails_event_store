# frozen_string_literal: true

require "spec_helper"
require "ruby_event_store/spec/dispatcher_lint"

module RubyEventStore
  ::RSpec.describe SyncScheduler do
    it_behaves_like "dispatcher", SyncScheduler.new
    let(:event) { instance_double(Event) }
    let(:record) { instance_double(Record) }
    let(:handler) { HandlerClass.new }

    specify "does not allow silly subscribers" do
      expect(SyncScheduler.new.verify(:symbol)).to be(false)
      expect(SyncScheduler.new.verify(Object.new)).to be(false)
    end

    specify "calls subscribed instance" do
      expect(handler).to receive(:call).with(event)
      SyncScheduler.new.call(handler, event, record)
    end

    specify "allows callable instances and lambdas" do
      expect(SyncScheduler.new.verify(HandlerClass.new)).to be(true)
      expect(SyncScheduler.new.verify(Proc.new { "yo" })).to be(true)
    end

    specify "does not allow classes" do
      expect(SyncScheduler.new.verify(HandlerClass)).to be(false)
    end

    private

    class HandlerClass
      @@received = nil
      def self.received
        @@received
      end
      def call(event)
        @@received = event
      end
    end
  end
end
