module CommandHandler
  def initialize(event_store)
    @repository = AggregateRoot::InstrumentedRepository.new(
      AggregateRoot::Repository.new(event_store),
      ActiveSupport::Notifications
    )
  end

  def with_aggregate(aggregate, aggregate_id, &block)
    stream = stream_name(aggregate.class, aggregate_id)
    repository.with_aggregate(aggregate, stream, &block)
  end

  private
  attr_reader :repository

  def stream_name(aggregate_class, aggregate_id)
    "#{aggregate_class.name}$#{aggregate_id}"
  end
end

