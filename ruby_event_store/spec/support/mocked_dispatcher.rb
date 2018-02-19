class CustomDispatcher
  attr_reader :dispatched_events

  def initialize
    @dispatched_events = []
  end

  def call(subscriber, event)
    subscriber = subscriber.new if Class === subscriber
    @dispatched_events << {to: subscriber.class, event: event}
  end

  def verify(subscriber)
    subscriber = subscriber.new if Class === subscriber
    subscriber.respond_to?(:call) or raise InvalidHandler.new(subscriber)
  rescue ArgumentError
    raise InvalidHandler.new(subscriber)
  end
end
