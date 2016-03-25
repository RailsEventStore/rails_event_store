require 'spec_helper'
require 'ruby_event_store/spec/event_repository_lint'

module RailsEventStoreActiveRecord
  describe EventRepository do
    it_behaves_like :event_repository, EventRepository
  end
end
