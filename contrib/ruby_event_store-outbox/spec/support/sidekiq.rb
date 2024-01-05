# frozen_string_literal: true

def reset_sidekiq_middlewares
  Sidekiq.configure_client { |config| config.client_middleware { |chain| chain.clear } }
end

def install_sidekiq_middleware(middleware_klass)
  Sidekiq.configure_client { |config| config.client_middleware { |chain| chain.add(middleware_klass) } }
end
