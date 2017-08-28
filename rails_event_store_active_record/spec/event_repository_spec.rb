require 'spec_helper'
require 'ruby_event_store'
require 'ruby_event_store/spec/event_repository_lint'

module RailsEventStoreActiveRecord
  describe EventRepository do
    it_behaves_like :event_repository, EventRepository

    specify 'initialize with adapter' do
      repository = EventRepository.new
      expect(repository.adapter).to eq(Event)
    end

    specify 'provide own event implementation' do
      CustomEvent = Class.new(ActiveRecord::Base)
      repository = EventRepository.new(adapter: CustomEvent)
      expect(repository.adapter).to eq(CustomEvent)
    end
  end
end
