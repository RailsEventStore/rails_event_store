require 'spec_helper'

module RailsEventStoreActiveRecord
  RSpec.describe WithDefaultModels do
    specify do
      event_klass, stream_klass = WithDefaultModels.new.call

      expect(event_klass).to eq(Event)
      expect(stream_klass).to eq(EventInStream)
    end
  end
end
