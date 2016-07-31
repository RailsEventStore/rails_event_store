require 'active_support/inflector'

module AggregateRoot
  class Base < Module
    def initialize(strategy = AggregateRoot::DefaultApplyStrategy)
      @strategy = strategy
    end

    private

    def included(descendant)
      super
      descendant.include Methods
      descendant.include @strategy
    end

    module Methods
      def apply(event)
        inject_apply_strategy! event
        unpublished_events << event
      end

      def apply_old_event(event)
        inject_apply_strategy! event
      end

      def unpublished_events
        @unpublished_events ||= []
      end

      attr_reader :id

      private
      attr_writer :id

      def generate_uuid
        SecureRandom.uuid
      end
    end
  end
end
