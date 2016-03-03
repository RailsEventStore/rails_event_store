require 'spec_helper'
require 'ruby_event_store/spec/event_repository_lint'

module RailsEventStore
  describe Repositories::EventRepository do
    it_behaves_like :event_repository, Repositories::EventRepository
  end
end
