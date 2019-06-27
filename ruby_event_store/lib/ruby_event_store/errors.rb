# frozen_string_literal: true

module RubyEventStore
  Error                     = Class.new(StandardError)
  WrongExpectedEventVersion = Class.new(Error)
  InvalidExpectedVersion    = Class.new(Error)
  IncorrectStreamData       = Class.new(Error)
  SubscriberNotExist        = Class.new(Error)
  InvalidPageStart          = Class.new(Error)
  InvalidPageStop           = Class.new(Error)
  InvalidPageSize           = Class.new(Error)
  EventDuplicatedInStream   = Class.new(Error)
  ReservedInternalName      = Class.new(Error)
  InvalidHandler            = Class.new(Error)
  ProtobufEncodingFailed    = Class.new(Error)

  class EventNotFound < Error
    attr_reader :event_id

    def initialize(event_id)
      super("Event not found: #{event_id}")
      @event_id = event_id
    end
  end
end
