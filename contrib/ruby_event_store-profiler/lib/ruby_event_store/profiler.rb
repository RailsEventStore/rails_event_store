module RubyEventStore
  class Profiler
    METRICS = [
      /rails_event_store/,
      /aggregate_root/,
      "total"
    ].freeze
    private_constant :METRICS

    def initialize(instrumenter)
      @instrumenter = instrumenter
    end

    def measure(&block)
      output =
        Hash.new(0)
      subscribers =
        METRICS.map do |name|
          @instrumenter.subscribe(name) do |name, start, finish|
            metric_name = name.split('.').first
            duration    = 1000.0 * (finish - start)
            output[metric_name] += duration
          end
        end

      @instrumenter.instrument('total') do
        block.call
      end

      subscribers.each do |name|
        @instrumenter.unsubscribe(name)
      end

      total = output.delete('total')

      puts "%s %s %s" % ["metric".ljust(18), "ms".rjust(7), "%".rjust(6)]
      puts "\u2500" * 33

      output.each do |metric, duration|
        puts "%s %7.2f %6.2f" % [metric.ljust(18), duration, (duration/total * 100)]
      end

      puts
      puts "%s %7.2f %6.2f" % ["total".ljust(18), total, 100]

      output.merge("total" => total)
    end
  end
end