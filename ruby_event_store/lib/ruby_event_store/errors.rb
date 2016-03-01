module RubyEventStore
  WrongExpectedEventVersion  = Class.new(StandardError)
  IncorrectStreamData        = Class.new(StandardError)
  EventNotFound              = Class.new(StandardError)
  SubscriberNotExist         = Class.new(StandardError)
  MethodNotDefined           = Class.new(StandardError)
  InvalidPageStart           = Class.new(ArgumentError)
  InvalidPageSize            = Class.new(ArgumentError)
end
