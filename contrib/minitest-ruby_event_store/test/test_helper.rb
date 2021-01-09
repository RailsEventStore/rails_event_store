require "minitest/ruby_event_store"
require "ruby_event_store"
require "mutant/minitest/coverage"
require "minitest/autorun"

class IdentityMapTransformation
  def initialize
    @identity_map = {}
  end

  def dump(domain_event)
    @identity_map[domain_event.event_id] = domain_event
    metadata = domain_event.metadata.to_h
    timestamp = metadata.delete(:timestamp)
    valid_at = metadata.delete(:valid_at)
    RubyEventStore::Record.new(
      event_id:   domain_event.event_id,
      metadata:   metadata,
      data:       domain_event.data,
      event_type: domain_event.event_type,
      timestamp:  timestamp,
      valid_at:   valid_at,
    )
  end

  def load(record)
    @identity_map.fetch(record.event_id)
  end
end


module TimeEnrichment
  def with(event, timestamp: Time.now.utc, valid_at: nil)
    event.metadata[:timestamp] ||= timestamp
    event.metadata[:valid_at] ||= valid_at || timestamp
    event
  end
  module_function :with
end
