module RubyEventStore
  WrongExpectedEventVersion = Class.new(StandardError)
  InvalidExpectedVersion    = Class.new(StandardError)
  IncorrectStreamData       = Class.new(StandardError)
  SubscriberNotExist        = Class.new(StandardError)
  InvalidPageStart          = Class.new(ArgumentError)
  InvalidPageSize           = Class.new(ArgumentError)
  EventDuplicatedInStream   = Class.new(StandardError)
  ReservedInternalName      = Class.new(StandardError)
  InvalidHandler            = Class.new(StandardError)
  ProtobufEncodingFailed    = Class.new(StandardError)

  class EventNotFound < StandardError
    attr_reader :event_id

    def initialize(event_id)
      super("Event not found: #{event_id}")
      @event_id = event_id
    end
  end
end
