module RailsEventStore
  class Event < RubyEventStore::Event
    def initialize(**args)
      attributes = args.except(:event_type, :event_id, :metadata)
      singleton_class = (class << self; self; end)
      attributes.each do |key, value|
        singleton_class.send(:define_method, key) { value }
      end

      event_data = {
        event_type: args[:event_type] || self.class.name,
        data:       attributes,
      }
      event_data[:event_id] = args[:event_id] if args.key?(:event_id)
      event_data[:metadata] = args[:metadata] if args.key?(:metadata)
      super(event_data)
    end
  end
end
