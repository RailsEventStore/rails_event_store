# frozen_string_literal: true

module RubyEventStore
  module OutboxRelay
    module Configuration
      class NotConfigured < StandardError; end

      class << self
        # @yieldparam batch_size [Integer]
        # @yieldparam poll_interval [Numeric]
        # @yieldparam logger [Logger]
        # @yieldreturn [Relay]
        def configure(&block)
          @build_block = block
        end

        def build(**overrides)
          raise NotConfigured, "call RubyEventStore::OutboxRelay::Configuration.configure first" unless @build_block
          @build_block.call(**overrides)
        end
      end
    end
  end
end
