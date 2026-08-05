# frozen_string_literal: true

module RailsEventStore
  class Configuration < RubyEventStore::Configuration
    attr_accessor :serializer, :request_metadata

    # Sets the defaults to the values a given version of RailsEventStore
    # shipped with. Upgrading the gem does not change the behaviour until
    # the loaded defaults version is bumped, which makes it possible to
    # opt in to new defaults one at a time:
    #
    #   RailsEventStore.configure do |config|
    #     config.load_defaults("3.0")
    #     config.serializer = JSON
    #   end
    #
    # @param version [String] defaults version, i.e. "3.0"
    # @return [self]
    def load_defaults(version)
      super
      case series(version)
      when "3.0"
        self.serializer = RubyEventStore::Serializers::YAML
        self.build_repository = -> { RubyEventStore::ActiveRecord::EventRepository.new(serializer: serializer) }
        self.build_subscriptions = -> {
          RubyEventStore::InstrumentedSubscriptions.new(RubyEventStore::Subscriptions.new, ActiveSupport::Notifications)
        }
        self.build_dispatcher = -> {
          RubyEventStore::InstrumentedDispatcher.new(
            RubyEventStore::ComposedDispatcher.new(
              AfterCommitDispatcher.new(scheduler: ActiveJobScheduler.new(serializer: serializer)),
              RubyEventStore::SyncScheduler.new,
            ),
            ActiveSupport::Notifications,
          )
        }
        self.request_metadata = ->(env) do
          request = ActionDispatch::Request.new(env)
          { remote_ip: request.remote_ip, request_id: request.uuid }
        end
      end
      self
    end
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
