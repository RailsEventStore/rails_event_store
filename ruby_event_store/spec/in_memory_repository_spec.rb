require 'spec_helper'

module RubyEventStore
  describe InMemoryRepository do
    it_behaves_like 'event_repository', InMemoryRepository
  end
end
