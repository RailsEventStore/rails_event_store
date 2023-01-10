# frozen_string_literal: true

module RailsEventStore
  class DefaultClientProfile
    def call(adapter)
      if adapter.downcase == "postgresql"
        <<~PROFILE
          RailsEventStore::Client.new(
            repository: RailsEventStoreActiveRecord::EventRepository.new(serializer: RubyEventStore::NULL),
            mapper: RubyEventStore::Mappers::PreserveTypesMapper.new
          )
        PROFILE
      else
        "RailsEventStore::Client.new"
      end
    end
  end
end
