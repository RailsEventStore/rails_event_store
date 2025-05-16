# frozen_string_literal: true

require "ruby_event_store"
require "protobuf_nested_struct"
require "google/protobuf"

module RubyEventStore
  ProtobufEncodingFailed = Class.new(Error)

  module Protobuf
  end
end

require_relative "protobuf/mappers/transformation/proto_event"
require_relative "protobuf/mappers/transformation/protobuf_encoder"
require_relative "protobuf/mappers/transformation/protobuf_nested_struct_metadata"
require_relative "protobuf/mappers/protobuf"
require_relative "protobuf/version"

module RubyEventStore
  Proto = Protobuf::Proto

  module Mappers
    Protobuf = RubyEventStore::Protobuf::Mappers::Protobuf

    module Transformation
      ProtoEvent = RubyEventStore::Protobuf::Mappers::Transformation::ProtoEvent
      ProtobufEncoder = RubyEventStore::Protobuf::Mappers::Transformation::ProtobufEncoder
      ProtobufNestedStructMetadata = RubyEventStore::Protobuf::Mappers::Transformation::ProtobufNestedStructMetadata
    end
  end
end
