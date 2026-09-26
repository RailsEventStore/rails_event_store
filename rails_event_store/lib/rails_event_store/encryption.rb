# frozen_string_literal: true

module RailsEventStore
  module Encryption
    def initialize(key_repository:, **kwargs)
      @key_repository = key_repository
      super(**kwargs)
    end

    private

    def transformations
      [RubyEventStore::Mappers::Transformation::Encryption.new(@key_repository, serializer: serializer), *super]
    end
  end
end
