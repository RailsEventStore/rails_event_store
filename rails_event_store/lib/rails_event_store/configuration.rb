# frozen_string_literal: true

module RailsEventStore
  # Defaults of RailsEventStore. Version dispatch lives in the parent class,
  # here only the values which differ from RubyEventStore are set.
  #
  #   RailsEventStore.configure do |config|
  #     config.load_defaults("3.0")
  #     config.serializer = JSON
  #   end
  class Configuration < RubyEventStore::Configuration
    attr_accessor :serializer, :request_metadata

    private

    def load_upcoming_defaults
      super
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
