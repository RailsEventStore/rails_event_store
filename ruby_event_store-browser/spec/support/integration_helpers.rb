module RubyEventStore
  module Browser
    module IntegrationHelpers
      class << self
        def included(base)
          base.include(with)
        end

        def with(app: ->(itself) { itself }, host: "www.example.com")
          Module.new do
            define_method :default_app do
              App.for(event_store_locator: -> { event_store })
            end

            define_method :web_client do
              @web_client ||= WebClient.new(app[default_app], host)
            end

            define_method :api_client do
              @api_client ||= ApiClient.new(app[default_app], host)
            end

            define_method :event_store do
              @event_store ||= RubyEventStore::Client.new(repository: RubyEventStore::InMemoryRepository.new)
            end
          end
        end
      end
    end
  end
end
