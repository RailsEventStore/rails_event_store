require 'active_support/inflector'
require 'aggregate_root/version'
require 'aggregate_root/configuration'
require 'aggregate_root/default_apply_strategy'

module AggregateRoot
  def apply(event)
    apply_strategy.(self, event)
    unpublished_events << event
  end

  def load(stream_name, event_store: default_event_store)
    @loaded_from_stream_name = stream_name
    events = event_store.read_stream_events_forward(stream_name)
    events.each do |event|
      apply(event)
    end
    @unpublished_events = []
    self
  end

  def store(stream_name = loaded_from_stream_name, event_store: default_event_store)
    unpublished_events.each do |event|
      event_store.publish_event(event, stream_name: stream_name)
    end
    @unpublished_events = []
  end

  private
  attr_reader :loaded_from_stream_name

  def unpublished_events
    @unpublished_events ||= []
  end

  def apply_strategy
    DefaultApplyStrategy.new
  end

  def default_event_store
    AggregateRoot.configuration.default_event_store
  end
end
