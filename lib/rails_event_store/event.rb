module RailsEventStore
  class Event < ::RubyEventStore::Event
    def initialize(**kwargs)
      super(metadata: Thread.current[:rails_event_store] || {}, **kwargs)
    end
  end
end
