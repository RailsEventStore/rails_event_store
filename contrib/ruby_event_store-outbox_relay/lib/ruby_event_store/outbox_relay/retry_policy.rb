# frozen_string_literal: true

module RubyEventStore
  module OutboxRelay
    # Decides whether a failed dispatch is retried, and when.
    #
    # The delay grows exponentially from base_delay, is capped at max_delay and
    # randomly stretched by up to jitter (a fraction of the delay), so messages
    # that failed together don't all come back at the same moment. With the
    # defaults, a message is dead-lettered after 25 attempts spread over roughly
    # 13 hours.
    class RetryPolicy
      # @param max_attempts [Integer] attempts after which a message is dead-lettered
      # @param base_delay [Numeric] seconds before the first retry
      # @param max_delay [Numeric] upper bound of a single delay, in seconds
      # @param jitter [Float] maximum random stretch of a delay, as a fraction of it
      # @param permanent_errors [Array<Class>] dispatch errors dead-lettered on
      #   first occurrence instead of being retried
      # @param random [Random]
      def initialize(
        max_attempts: 25,
        base_delay: 1,
        max_delay: 3600,
        jitter: 0.2,
        permanent_errors: [],
        random: Random.new
      )
        raise ArgumentError, "max_attempts must be at least 1" if max_attempts < 1
        @max_attempts = max_attempts
        @base_delay = base_delay
        @max_delay = max_delay
        @jitter = jitter
        @permanent_errors = permanent_errors
        @random = random
      end

      attr_reader :max_attempts

      # @param error [Exception] the dispatch failure
      # @param attempts [Integer] attempts made so far, including the failed one
      # @return [Boolean]
      def retry?(error, attempts)
        attempts < max_attempts && permanent_errors.none? { |klass| klass === error }
      end

      # @param attempts [Integer] attempts made so far, including the failed one
      # @param now [Time]
      # @return [Time] when the next attempt is due
      def next_attempt_at(attempts, now)
        delay = [base_delay * (2**(attempts - 1)), max_delay].min
        now + (delay * (1 + (jitter * random.rand)))
      end

      private

      attr_reader :base_delay, :max_delay, :jitter, :permanent_errors, :random
    end
  end
end
