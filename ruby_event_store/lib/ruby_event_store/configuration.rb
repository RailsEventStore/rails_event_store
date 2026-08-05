# frozen_string_literal: true

module RubyEventStore
  class Configuration
    def initialize
      load_defaults(VERSION)
    end

    attr_reader :loaded_defaults

    attr_accessor :build_repository,
                  :build_mapper,
                  :build_subscriptions,
                  :build_dispatcher,
                  :build_message_broker,
                  :build_event_type_resolver,
                  :clock,
                  :correlation_id_generator

    # Sets the defaults to the values a given version of RubyEventStore
    # shipped with. Upgrading the gem does not change the behaviour until
    # the loaded defaults version is bumped, which makes it possible to
    # opt in to new defaults one at a time:
    #
    #   RubyEventStore.configure do |config|
    #     config.load_defaults("3.0")
    #     config.build_dispatcher = -> { RubyEventStore::ImmediateDispatcher.new }
    #   end
    #
    # The branch of the version being worked on is matched dynamically and gets
    # frozen to the released number when the release is made — see RELEASE.md.
    #
    # @param version [String] defaults version, i.e. "3.0"
    # @return [self]
    def load_defaults(version)
      defaults = series(version)
      case defaults
      when series(VERSION)
        load_upcoming_defaults
      else
        raise UnknownDefaults.new(version)
      end
      @loaded_defaults = defaults
      self
    end

    private

    def load_upcoming_defaults
      self.build_repository = -> { InMemoryRepository.new }
      self.build_mapper = -> { Mappers::BatchMapper.new }
      self.build_subscriptions = -> { Subscriptions.new }
      self.build_dispatcher = -> { SyncScheduler.new }
      self.build_message_broker = -> {
        Broker.new(subscriptions: build_subscriptions.call, dispatcher: build_dispatcher.call)
      }
      self.build_event_type_resolver = -> { EventTypeResolver.new }
      self.clock = default_clock
      self.correlation_id_generator = default_correlation_id_generator
    end

    def series(version)
      version.to_s.split(".").take(2).join(".")
    end

    def default_clock = -> { Time.now.utc.round(TIMESTAMP_PRECISION) }
    def default_correlation_id_generator = -> { SecureRandom.uuid }
  end

  class << self
    def configuration
      @configuration ||= Configuration.new
    end

    def configure
      yield(configuration)
    end
  end
end
