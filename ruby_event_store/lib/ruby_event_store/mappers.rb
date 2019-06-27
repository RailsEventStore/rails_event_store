# frozen_string_literal: true

module RubyEventStore
  module Mappers
    def self.const_missing(const_name)
      super unless const_name.equal?(:MissingEncryptionKey)
      warn "`RubyEventStore::Mappers::MissingEncryptionKey` has been deprecated. Use `RubyEventStore::Mappers::Transformation::Encryption::MissingEncryptionKey` instead."

      Transformation::Encryption::MissingEncryptionKey
    end
  end
end
