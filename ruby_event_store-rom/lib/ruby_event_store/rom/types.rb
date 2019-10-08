# frozen_string_literal: true

module RubyEventStore
  module ROM
    module Types
      Time = ::ROM::Types::Time
                 .constructor do |value|
                   case value
                   when nil
                     Dry::Core::Constants::Undefined
                   when ::String
                     ::Time.iso8601(value)
                   else
                     value
                   end
                 end
                 .default { ::Time.now.utc }

      SerializedRecordSerializer = ::ROM::Types::String
      # detects if the value is a Sequel::Postgres::JSONHash or Sequel::Postgres::JSONBHash
      SerializedRecordDeserializer = ::ROM::Types::String.constructor { |v| v.class.name.upcase.include?('JSON') ? JSON.dump(v) : v }
    end
  end
end
