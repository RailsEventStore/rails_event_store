# frozen_string_literal: true

require 'ruby_event_store'

module RubyEventStore
  ProtobufEncodingFailed = Class.new(Error)

  module Protobuf
  end
end

require 'ruby_event_store/mappers/transformation/proto_event'
require 'ruby_event_store/mappers/transformation/protobuf_encoder'
require 'ruby_event_store/mappers/transformation/protobuf_nested_struct_metadata'
require 'ruby_event_store/mappers/protobuf'
require 'ruby_event_store/protobuf/version'
