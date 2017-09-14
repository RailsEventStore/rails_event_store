require 'active_support/inflector'
require 'aggregate_root/version'
require 'aggregate_root/configuration'
require 'aggregate_root/default_apply_strategy'

module AggregateRoot
  def apply(*events)
    events.each do |event|
      apply_strategy.(self, event)
      unpublished_events << event
    end
  end

  def load(stream_name, event_store: default_event_store)
    @loaded_from_stream_name = stream_name
    events = event_store.read_stream_events_forward(stream_name)
    events.each do |event|
      apply(event)
    end
    @version = events.size - 1
    @unpublished_events = nil
    self
  end

  def store(stream_name = loaded_from_stream_name, event_store: default_event_store)
    event_store.publish_events(unpublished_events, stream_name: stream_name, expected_version: version)
    @version += unpublished_events.size
    @unpublished_events = nil
  end

  private
  attr_reader :loaded_from_stream_name

  def unpublished_events
    @unpublished_events ||= []
  end

  def version
    @version ||= -1
  end

  def apply_strategy
    DefaultApplyStrategy.new
  end

  def default_event_store
    AggregateRoot.configuration.default_event_store
  end
end
