# frozen_string_literal: true

module RubyEventStore
  module ROM
    module Types
      DateTime = ::ROM::Types::DateTime
                 .constructor do |value|
                   case value
                   when nil
                     Dry::Core::Constants::Undefined
                   when ::String
                     ::DateTime.iso8601(value)
                   else
                     value
                   end
                 end
                 .default { ::DateTime.now.new_offset(0) }

      RecordSerializer = ::ROM::Types::String
      # detects if the value is a Sequel::Postgres::JSONHash or Sequel::Postgres::JSONBHash
      RecordDeserializer = ::ROM::Types::String.constructor { |v| v.class.name.upcase.include?('JSON') ? JSON.dump(v) : v }
    end
  end
end
