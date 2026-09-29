# frozen_string_literal: true

module RailsEventStore
  module Inspector
    ::RSpec.describe Collector do
      let(:buffer) { Buffer.new }
      let(:notifications) { ActiveSupport::Notifications }

      before { Collector.new(buffer, notifications).subscribe }
      after { notifications.unsubscribe("call.broker.ruby_event_store") }

      def publish(event, subscribers: [], &block)
        watching { publish_now(event, subscribers: subscribers, &block) }
      end

      def publish_now(event, subscribers: [])
        notifications.instrument("call.broker.ruby_event_store", event: event) do
          subscribers.each do |subscriber|
            notifications.instrument("call.dispatcher.ruby_event_store", event: event, subscriber: subscriber) do
              yield subscriber if block_given?
            end
          end
        end
      end

      def entries_of(kind)
        buffer.to_a.select { |e| e[:kind] == kind }
      end

      specify "records a published event with its metadata" do
        publish(fake_event(id: "evt-1", type: "Ordering::OrderSubmitted", request_id: "req-1"))

        expect(entries_of(:event).first).to include(
          event_id: "evt-1",
          event_type: "Ordering::OrderSubmitted",
          request_id: "req-1",
        )
      end

      specify "carries the ids the causation tree will be built from" do
        publish(fake_event(id: "evt-1", causation_id: "parent", correlation_id: "corr"))

        expect(entries_of(:event).first).to include(causation_id: "parent", correlation_id: "corr")
      end

      specify "records each subscriber that took the event" do
        publish(fake_event, subscribers: [String, Integer])

        expect(entries_of(:handler).map { |e| e[:subscriber] }).to contain_exactly("String", "Integer")
      end

      specify "an event nobody took leaves no handler entries at all" do
        publish(fake_event)

        expect(entries_of(:handler)).to be_empty
      end

      specify "attributes an event published inside a handler to that handler" do
        parent = fake_event(id: "parent")
        child = fake_event(id: "child")

        publish(parent, subscribers: [String]) { publish_now(child) }

        expect(entries_of(:event).find { |e| e[:event_id] == "child" }[:producer]).to eq("String")
      end

      specify "an event published outside any handler has no producer" do
        publish(fake_event(id: "lonely"))

        expect(entries_of(:event).first[:producer]).to be_nil
      end

      specify "nesting does not confuse the stacks" do
        publish(fake_event(id: "outer"), subscribers: [String]) do
          publish_now(fake_event(id: "inner"), subscribers: [Integer])
        end

        producers = entries_of(:event).to_h { |e| [e[:event_id], e[:producer]] }
        expect(producers).to eq("inner" => "String", "outer" => nil)
      end

      specify "marks RES built-in subscribers as infrastructure" do
        stub_const("RubyEventStore::LinkByEventType", Class.new)
        publish(fake_event, subscribers: [RubyEventStore::LinkByEventType, String])

        infra, own = entries_of(:handler).partition { |e| e[:infra] }

        expect(infra.map { |e| e[:subscriber] }).to eq(["RubyEventStore::LinkByEventType"])
        expect(own.map { |e| e[:subscriber] }).to eq(["String"])
      end

      describe "asynchronous handlers" do
        before { stub_const("ActiveJob::Base", Class.new) }

        specify "an ActiveJob class is marked as asynchronous" do
          job = Class.new(ActiveJob::Base)
          stub_const("MailerJob", job)

          publish(fake_event, subscribers: [MailerJob])

          expect(entries_of(:handler).first).to include(subscriber: "MailerJob", async: true)
        end

        specify "an ordinary subscriber is not" do
          publish(fake_event, subscribers: [String])

          expect(entries_of(:handler).first[:async]).to be(false)
        end

        specify "reaching the queue is recorded separately" do
          job = Struct.new(:x).new(1)
          stub_const("MailerJob", job.class)

          watching { notifications.instrument("enqueue.active_job", job: job) {} }

          expect(entries_of(:enqueued).first).to include(job: job.class.name)
        end

        specify "a scheduled job that never reached the queue leaves no enqueue entry" do
          job = Class.new(ActiveJob::Base)
          stub_const("MailerJob", job)

          publish(fake_event, subscribers: [MailerJob])

          expect(entries_of(:handler).first[:async]).to be(true)
          expect(entries_of(:enqueued)).to be_empty
        end
      end

      describe "streams" do
        def append(records, stream_name)
          stream = Struct.new(:name).new(stream_name)
          watching do
            notifications.instrument("append_to_stream.repository.ruby_event_store", records: records, stream: stream) {}
          end
        end

        specify "records which stream an event was written to" do
          append([Struct.new(:event_id).new("evt-1")], "Ordering::Order$123")

          expect(entries_of(:stream).first).to include(event_id: "evt-1", stream: "Ordering::Order$123")
        end

        specify "records one entry per record in the batch" do
          record = Struct.new(:event_id)
          append([record.new("evt-1"), record.new("evt-2")], "Ordering::Order$123")

          expect(entries_of(:stream).map { |e| e[:event_id] }).to eq(["evt-1", "evt-2"])
        end

        specify "carries no request of its own — the event it belongs to has one" do
          append([Struct.new(:event_id).new("evt-1")], "some-stream")

          expect(entries_of(:stream).first).not_to have_key(:request_id)
        end
      end

      specify "gathers nothing while the inspector is switched off" do
        publish_now(fake_event, subscribers: [String])

        expect(buffer.to_a).to be_empty
      end

      specify "the frame stack stays balanced when switched off mid-flight" do
        publish_now(fake_event, subscribers: [String])
        publish(fake_event(id: "later"), subscribers: [String])

        expect(entries_of(:event).map { |e| e[:event_id] }).to eq(["later"])
        expect(entries_of(:handler).size).to eq(1)
      end

      specify "labels a lambda subscriber with its source location" do
        publish(fake_event, subscribers: [->(_) {}])

        expect(entries_of(:handler).first[:subscriber]).to match(%r{#<Proc @ .*collector_spec\.rb:\d+>})
      end

      describe "never breaking the application it watches" do
        specify "an event of an unexpected shape is skipped, not raised" do
          expect { watching { publish_now(Object.new) } }.not_to raise_error
        end

        specify "a subscriber of an unexpected shape is skipped" do
          expect { watching { publish_now(fake_event, subscribers: [Object.new]) } }.not_to raise_error
        end

        specify "a record of an unexpected shape is skipped" do
          expect do
            watching do
              notifications.instrument(
                "append_to_stream.repository.ruby_event_store",
                records: [Object.new],
                stream: Object.new,
              ) {}
            end
          end.not_to raise_error
        end

        specify "a job of an unexpected shape is skipped" do
          expect { watching { notifications.instrument("enqueue.active_job", job: nil) {} } }.not_to raise_error
        end

        specify "the application's own work still runs" do
          ran = false

          watching { publish_now(Object.new) { ran = true } }

          expect { watching { publish_now(Object.new, subscribers: [String]) { ran = true } } }.not_to raise_error
          expect(ran).to be(true)
        end

        specify "hands the failure to wherever the application collects errors" do
          reporter = double
          stub_const("Rails", double(error: reporter))
          expect(reporter).to receive(:report).with(
            instance_of(NoMethodError),
            hash_including(handled: true, severity: :warning),
          )

          watching { publish_now(Object.new) }
        end

        specify "falls back to stderr when there is no Rails to tell" do
          expect { watching { publish_now(Object.new) } }.to output(/collecting failed/).to_stderr
        end

        specify "a reporter that itself fails does not take the request down" do
          reporter = double
          stub_const("Rails", double(error: reporter))
          allow(reporter).to receive(:report).and_raise("the reporter is down too")

          expect { watching { publish_now(Object.new) } }.not_to raise_error
        end
      end

      specify "survives an event whose metadata cannot be read" do
        broken =
          Class.new do
            def event_id = "evt-1"
            def event_type = "Broken"
            def metadata = raise("no metadata here")
          end.new

        expect { publish(broken) }.not_to raise_error
        expect(entries_of(:event).first).to include(event_id: "evt-1", request_id: nil)
      end
    end
  end
end
