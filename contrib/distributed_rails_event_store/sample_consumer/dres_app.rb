class DresApp
  def initialize(client:, logger:, processor:)
    self.exit_now  = false
    self.client    = client
    self.logger    = logger
    self.processor = processor
  end

  def run
    q = DresRails::Queue.find_or_create_by!(name: "sample_consumer")
    after_event_id = q.last_processed_event_id

    client.run(after_event_id: after_event_id) do |events|
      sleep(0.5) if events.empty?
      throw :exit_now if exit_now

      events.each do |event|
        throw :exit_now if exit_now

        q.process(event.event_id) do
          processor.call(event)
        end
      end

      events.last(1).each do |last|
        q.update_attributes!(last_processed_event_id: last.event_id)
      end
    end
  end

  def soft_exit!
    self.exit_now = true
  end

  def trap_signals
    Signal.trap('INT')  { self.soft_exit! }
    Signal.trap('TERM') { self.soft_exit! }
  end

  private
  attr_accessor :exit_now, :client, :logger, :processor
end

