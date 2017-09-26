module RubyEventStore
  WrongExpectedEventVersion  = Class.new(StandardError)
  InvalidExpectedVersion     = Class.new(StandardError)
  IncorrectStreamData        = Class.new(StandardError)
  EventNotFound              = Class.new(StandardError)
  SubscriberNotExist         = Class.new(StandardError)
  InvalidPageStart           = Class.new(ArgumentError)
  InvalidPageSize            = Class.new(ArgumentError)
  EventDuplicatedInStream    = Class.new(StandardError)

  class InvalidHandler < StandardError
    def initialize(subscriber_klass)
      super("#call method not found in #{subscriber_klass} subscriber. Are you sure it is a valid subscriber?")
    end
  end
end
