# frozen_string_literal: true

module RubyEventStore
  module OutboxRelay
    module Configuration
      class NotConfigured < StandardError; end

      class << self
        # Sets how the command line builds the relay. The block receives the
        # options the command line gave, as keywords (+batch_size+, +poll_interval+,
        # +lease_duration+, +stats_interval+, always +logger+), and passes them on:
        #
        #   Configuration.configure { |**options| Relay.new(client: client, **options) }
        #
        # @yieldparam options [Hash] the options given on the command line
        # @yieldreturn [Relay]
        def configure(&block)
          @build_block = block
        end

        # @raise [NotConfigured] before #configure was called
        # @raise [ArgumentError] when the block can't take one of the overrides, which
        #   would otherwise be ignored without a word
        def build(**overrides)
          raise NotConfigured, "call RubyEventStore::OutboxRelay::Configuration.configure first" unless @build_block
          ignored = ignored_by(@build_block, overrides.keys)
          unless ignored.empty?
            raise ArgumentError,
                  "the configure block ignores #{ignored.join(", ")}: " \
                    "declare them, or take **options and pass them on to Relay.new"
          end
          @build_block.call(**overrides)
        end

        private

        def ignored_by(block, keys)
          parameters = block.parameters
          return [] if parameters.any? { |type, _| type == :keyrest }
          keys - parameters.select { |type, _| %i[key keyreq].include?(type) }.map(&:last)
        end
      end
    end
  end
end
