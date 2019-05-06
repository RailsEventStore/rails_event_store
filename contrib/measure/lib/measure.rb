require "measure/version"

module Measure
  METRICS = %w(
      append_to_stream.repository.rails_event_store
      link_to_stream.repository.rails_event_store
      delete_stream.repository.rails_event_store
      read_event.repository.rails_event_store
      read.repository.rails_event_store
      call.dispatcher.rails_event_store
      serialize.mapper.rails_event_store
      deserialize.mapper.rails_event_store
      total
    ).freeze

  def measure(&block)
    output = Hash.new { |hash, key| hash[key] = 0 }

    METRICS.each do |name|
      ActiveSupport::Notifications.subscribe(name) do |name, start, finish, id, payload|
        metric = ActiveSupport::Notifications::Event.new(name, start, finish, id, payload)
        metric_name = name.split('.').first
        output[metric_name] += metric.duration
      end
    end

    ActiveSupport::Notifications.instrument('total') do
      block.call
    end

    METRICS.each do |name|
      ActiveSupport::Notifications.unsubscribe(name)
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
  module_function :measure
end
