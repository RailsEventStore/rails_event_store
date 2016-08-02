require 'active_support/inflector'

module AggregateRoot
  module Base
    def apply(event)
      apply_event(event)
      unpublished_events << event
    end

    def apply_old_event(event)
      apply_event(event)
    end

    def unpublished_events
      @unpublished_events ||= []
    end

    attr_reader :id

    private
    attr_writer :id

    def apply_strategy
      @apply_strategy || AggregateRoot::DefaultApplyStrategy.new
    end

    def apply_event(event)
      apply_strategy.handle(event, self)
    end

    def generate_uuid
      SecureRandom.uuid
    end
  end
end
