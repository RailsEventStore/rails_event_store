def reset_sidekiq_middlewares
  Sidekiq.configure_client do |config|
    config.client_middleware do |chain|
      chain.clear
    end
  end
end

def install_sidekiq_middleware(middleware_klass)
  Sidekiq.configure_client do |config|
    config.client_middleware do |chain|
      chain.add(middleware_klass)
    end
  end
end
