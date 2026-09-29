# frozen_string_literal: true

require "spec_helper"
require "rake"

module RubyEventStore
  module OutboxRelay
    ::RSpec.describe "dead letters rake tasks" do
      helper = SpecHelper.new

      around { |example| helper.run_lifecycle { example.run } }

      around do |example|
        original = Rake.application
        database_url = ENV.delete("DATABASE_URL")
        Rake.application = Rake::Application.new
        Rake::Task.define_task(:environment)
        load File.expand_path("../lib/tasks/outbox_relay.rake", __dir__)
        example.run
      ensure
        ENV["DATABASE_URL"] = database_url
        Rake.application = original
      end

      let(:now) { Time.utc(2026, 9, 29, 12) }

      def dead_letter(topic: "TestEvent", subscriber: "OrderReport")
        DeadLetter.create!(
          event_id: SecureRandom.uuid,
          topic: topic,
          subscriber: subscriber,
          attempts: 25,
          error_class: "RuntimeError",
          error_message: "boom",
          first_enqueued_at: now,
          dead_at: now,
        )
      end

      def invoke(task, *args)
        Rake::Task["ruby_event_store:outbox_relay:dead_letters:#{task}"].invoke(*args)
      end

      specify "list prints one tab-separated line per dead letter, without the error message" do
        first = dead_letter

        expect { invoke("list") }.to output(
          "#{first.id}\t#{first.event_id}\tTestEvent\tOrderReport\t25\tRuntimeError\t2026-09-29T12:00:00Z\n",
        ).to_stdout
      end

      specify "retry with an id requeues that dead letter" do
        requeued, kept = dead_letter, dead_letter

        expect { invoke("retry", requeued.id.to_s) }.to output("Requeued dead letter #{requeued.id}\n").to_stdout

        expect(Message.pluck(:event_id)).to eq([requeued.event_id])
        expect(DeadLetter.pluck(:id)).to eq([kept.id])
      end

      specify "retry all requeues every dead letter matching TOPIC and SUBSCRIBER" do
        matching = dead_letter(topic: "A", subscriber: "X")
        dead_letter(topic: "A", subscriber: "Y")
        ENV["TOPIC"], ENV["SUBSCRIBER"] = "A", "X"

        expect { invoke("retry", "all") }.to output("Requeued 1 dead letter(s)\n").to_stdout

        expect(Message.pluck(:event_id)).to eq([matching.event_id])
      ensure
        ENV.delete("TOPIC")
        ENV.delete("SUBSCRIBER")
      end

      specify "retry rejects an id that is not a number" do
        expect { invoke("retry", "abc") }.to raise_error(ArgumentError)
      end

      specify "run splits OUTBOX_RELAY_ARGS like a shell, honoring quotes" do
        ENV["OUTBOX_RELAY_ARGS"] = %(--require="path with spaces/relay.rb" --batch-size=5)
        cli = instance_double(CLI, run: nil)
        allow(CLI).to receive(:new).and_return(cli)

        Rake::Task["ruby_event_store:outbox_relay:run"].invoke

        expect(cli).to have_received(:run).with(["--require=path with spaces/relay.rb", "--batch-size=5"])
      ensure
        ENV.delete("OUTBOX_RELAY_ARGS")
      end

      specify "discard deletes the dead letter" do
        discarded = dead_letter

        expect { invoke("discard", discarded.id.to_s) }.to output("Discarded dead letter #{discarded.id}\n").to_stdout

        expect(DeadLetter.count).to eq(0)
      end
    end
  end
end
