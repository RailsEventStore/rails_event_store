module RubyEventStore
  module ROM
    module Types
      DateTime = ::ROM::Types::DateTime
                  .constructor { |value| value.is_a?(::String) ? ::DateTime.iso8601(value) : value }
                  .default { ::DateTime.now.new_offset(0) }

      SerializedRecordSerializer = ::ROM::Types::String
      # detects if the value is a Sequel::Postgres::JSONHash or Sequel::Postgres::JSONBHash
      SerializedRecordDeserializer = ::ROM::Types::String.constructor { |v| v.class.name.upcase.include?('JSON') ? JSON.dump(v) : v }
    end
  end
end
