module RailsEventStore
  WrongExpectedEventVersion  = Class.new(StandardError)
  IncorrectStreamData        = Class.new(StandardError)
end