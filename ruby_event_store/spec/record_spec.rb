require 'spec_helper'

module RubyEventStore
  RSpec.describe Record do
    specify 'constructor accept all arguments and returns frozen instance' do
      event_id   = "event_id"
      data       = { foo: :bar }
      metadata   = { baz: :bax }
      event_type = "event_type"
      record     = Record.new(event_id: event_id, data: data, metadata: metadata, event_type: event_type)
      expect(record.event_id).to be event_id
      expect(record.metadata).to be metadata
      expect(record.data).to be data
      expect(record.event_type).to be event_type
      expect(record.frozen?).to be true
    end
  end
end