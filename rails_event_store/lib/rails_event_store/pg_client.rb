# frozen_string_literal: true

module RailsEventStore
  class PgClient < Client
    def initialize
      super(
        repository: RubyEventStore::ActiveRecord::EventRepository.new(serializer: RubyEventStore::NULL),
        mapper: RubyEventStore::Mappers::PreserveTypesMapper.new
      )
    end
  end
end
