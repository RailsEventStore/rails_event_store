module ProtobufHelper
  def require_protobuf_dependencies
    begin
      require_relative '../ruby_event_store/spec/mappers/events_pb'
      require 'protobuf_nested_struct'
    rescue LoadError => exc
      skip if cannot_compile?(exc)
    end
  end

  def cannot_compile?(exc)
    exc.message == 'cannot load such file -- google/protobuf_c'
  end
end