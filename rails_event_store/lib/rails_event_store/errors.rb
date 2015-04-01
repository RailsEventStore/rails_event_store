module RailsEventStore
  WrongExpectedEventVersion  = Class.new(StandardError)
  IncorrectStreamData        = Class.new(StandardError)
  EventCannotBeSaved         = Class.new(StandardError)
  EventNotFound              = Class.new(StandardError)
end