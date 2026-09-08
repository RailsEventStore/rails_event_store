# frozen_string_literal: true

require "spec_helper"
require "ruby_event_store/spec/scheduler_lint"
require "rails_event_store/spec/buffering_scheduler_lint"

module RailsEventStore
  class CollectingScheduler
    include BufferingScheduler

    attr_reader :shipped

    def initialize
      @shipped = []
    end

    def call(_, record)
      buffer << record
    end

    def verify(_)
      true
    end

    private

    def ship(entries)
      @shipped << entries
    end
  end

  class ComparableScheduler < CollectingScheduler
    def hash
      self.class.hash
    end

    def eql?(other)
      other.instance_of?(self.class)
    end

    def ==(other)
      eql?(other)
    end
  end

  ::RSpec.describe BufferingScheduler do
    it_behaves_like "scheduler", CollectingScheduler.new
    it_behaves_like "buffering scheduler", CollectingScheduler.new

    let(:scheduler) { CollectingScheduler.new }

    describe "#flush" do
      specify "ships everything buffered in a single call" do
        scheduler.call(Object, "first")
        scheduler.call(Object, "second")
        scheduler.flush

        expect(scheduler.shipped).to eq([%w[first second]])
      end

      specify "does nothing when there is nothing buffered" do
        scheduler.flush

        expect(scheduler.shipped).to be_empty
      end

      specify "is idempotent" do
        scheduler.call(Object, "first")
        scheduler.flush
        scheduler.flush

        expect(scheduler.shipped).to eq([%w[first]])
      end

      specify "drops the buffer when shipping blows up, so it cannot leak into the next flush" do
        allow(scheduler).to receive(:ship).and_raise("backend is down")
        scheduler.call(Object, "first")
        expect { scheduler.flush }.to raise_error("backend is down")

        allow(scheduler).to receive(:ship).and_call_original
        scheduler.call(Object, "second")
        scheduler.flush

        expect(scheduler.shipped).to eq([%w[second]])
      end

      specify "forgets the scheduler, so a long-lived thread does not accumulate buffers" do
        scheduler.call(Object, "first")
        scheduler.flush

        expect(Thread.current[BufferingScheduler::BUFFER_KEY]).not_to have_key(scheduler)
      end
    end

    describe "#buffer" do
      specify "keeps buffers of separate scheduler instances apart" do
        other_scheduler = CollectingScheduler.new

        scheduler.call(Object, "mine")
        other_scheduler.call(Object, "theirs")
        scheduler.flush

        expect(scheduler.shipped).to eq([%w[mine]])
        expect(other_scheduler.shipped).to be_empty
      end

      specify "keeps them apart even when the schedulers compare equal" do
        scheduler = ComparableScheduler.new
        other_scheduler = ComparableScheduler.new

        scheduler.call(Object, "mine")
        other_scheduler.call(Object, "theirs")
        scheduler.flush

        expect(scheduler.shipped).to eq([%w[mine]])
        expect(other_scheduler.shipped).to be_empty
      end
    end
  end
end
