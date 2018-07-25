require 'timeout'
require 'thread'

# Simple queue-based debouncer which can execute only single type of job
# and does not support passing any arguments to the debounced job.
#
# You can use it for sending notifications about new events which
# occurred in your system.
#
# Normally it waits job time + delay time between invocations.
# The first invocation is scheduled immediately and does not wait 'delay'
# amount of time.
#
# The job is invoked once again no matter how many times it was scheduled
# with call() in the time between previous invocation and now.
class RubyEventStore::Debouncer
  # @param delay [Float] number of seconds to wait after job is finished before invoking it again
  # @param timeout [Float] timeout after which the job is cancelled
  # @param job [Proc] the debounced job to invoke periodically
  def initialize(delay: 0.0, timeout: 2.0, &job)
    @delay = delay
    @timeout = timeout
    @job = job

    @queue = Queue.new
    @consumer = create_consumer(@job)
  end

  # Schedules debounced job invocation
  # @return self
  def call
    create_consumer_if_dead
    @queue << nil
    self
  end

  private

  def create_consumer_if_dead
    @consumer = create_consumer(@job) unless @consumer.status
  end

  def create_consumer(job)
    Thread.new do
      loop do
        @queue.pop
        @queue.clear
        Timeout.timeout(@timeout) do
          job.call
        end
        sleep(@delay)
      rescue Timeout::Error
      rescue StandardError
        sleep(@delay)
      end
    end
  end

end