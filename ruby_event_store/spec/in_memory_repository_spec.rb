require 'spec_helper'
require 'ruby_event_store/spec/event_repository_lint'

module RubyEventStore
  describe InMemoryRepository do
    it_behaves_like :event_repository, InMemoryRepository
  end
end
