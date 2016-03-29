module RailsEventStore
  class << self
    attr_writer :configuration
  end

  def self.configuration
    @configuration ||= Configuration.new
  end

  def self.reset
    @configuration = Configuration.new
  end

  def self.configure
    yield(configuration)
  end

  class Configuration
    attr_accessor :event_repository, :event_broker, :page_size

    def initialize
      @event_repository ||= RailsEventStoreActiveRecord::EventRepository.new
      @event_broker     ||= RailsEventStore::EventBroker.new
      @page_size        ||= RailsEventStore::PAGE_SIZE
    end
  end
end
