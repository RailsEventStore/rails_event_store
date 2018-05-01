module RubyEventStore
  WrongExpectedEventVersion  = Class.new(StandardError)
  InvalidExpectedVersion     = Class.new(StandardError)
  IncorrectStreamData        = Class.new(StandardError)
  SubscriberNotExist         = Class.new(StandardError)
  InvalidPageStart           = Class.new(ArgumentError)
  InvalidPageSize            = Class.new(ArgumentError)
  EventDuplicatedInStream    = Class.new(StandardError)
  NotSupported               = Class.new(StandardError)
  ReservedInternalName       = Class.new(StandardError)

  class EventNotFound < StandardError
    attr_reader :event_id
    def initialize(event_id)
      super("Event not found: #{event_id}")
      @event_id = event_id
    end
  end

  class InvalidHandler < StandardError
    def initialize(object)
      super("#call method not found in #{object.inspect} subscriber. Are you sure it is a valid subscriber?")
    end
  end
end
