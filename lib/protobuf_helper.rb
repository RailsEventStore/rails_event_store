module ProtobufHelper
  def require_protobuf_dependencies
    begin
      require_relative '../ruby_event_store/spec/mappers/events_pb'
      require 'protobuf_nested_struct'
    rescue LoadError => exc
      skip if unsupported_ruby_version
    end
  end

  def unsupported_ruby_version
    truffleruby || jruby || ruby_2_6_0
  end

  def truffleruby
    RUBY_ENGINE == "truffleruby"
  end

  def jruby
    RUBY_PLATFORM == "java"
  end

  def ruby_2_6_0
    RUBY_VERSION == "2.6.0"
  end
end
