require 'spec_helper'

module RubyEventStore
  RSpec.describe Profiler do
    let(:event_store) do
      asn = ActiveSupport::Notifications
      RubyEventStore::Client.new(
        repository: RubyEventStore::InstrumentedRepository.new(RubyEventStore::InMemoryRepository.new, asn),
        mapper: RubyEventStore::Mappers::InstrumentedMapper.new(RubyEventStore::Mappers::Default.new, asn),
        dispatcher: RubyEventStore::InstrumentedDispatcher.new(RubyEventStore::Dispatcher.new, asn)
      )
    end

    DummyEvent = Class.new(RubyEventStore::Event)

    class StepClock
      def initialize(initial_time, step_duration = 1)
        @initial_time  = initial_time
        @step_duration = step_duration
        @step          = 0
      end

      def now
        current_time = @initial_time + (@step * @step_duration)
        @step += 1
        current_time
      end
    end

    let(:step_clock) { StepClock.new(Time.at(0)) }

    specify do
      operation = -> do
        event_store.publish(DummyEvent.new)
      end

      allow(Time).to receive(:now) { step_clock.now }

      expect { Profiler.measure(&operation) }.to output(<<~EOS).to_stdout
        metric                  ms      %
        ─────────────────────────────────
        serialize          1000.00  16.67
        append_to_stream   1000.00  16.67
  
        total              6000.00 100.00
      EOS
    end

    specify do
      operation = -> do
        event_store.publish(DummyEvent.new)
      end

      allow(Time).to receive(:now) { step_clock.now }

      begin
        $stdout = File.open('/dev/null', 'w')
        return_value = Profiler.measure(&operation)
      ensure
        $stdout = STDOUT
      end

      expect(return_value).to eq({
        "total" => 6000,
        "serialize" => 1000.0,
        "append_to_stream" => 1000.0
      })
    end
  end
end