require 'active_job'

module RailsEventStore

  class ActiveJobDispatcher < AsyncDispatcher
    def initialize(proxy_strategy: AsyncProxyStrategy::Inline.new)
      super(proxy_strategy: proxy_strategy)
    end
  end
end
