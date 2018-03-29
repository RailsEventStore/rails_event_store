require 'ostruct'
require 'thread'

module RubyEventStore
  module Repository
    POSITION_SHIFT = 1
    POSITION_DEFAULT = -1

    def append_to_stream(events, stream_name, expected_version)
      add_to_stream(events, stream_name, expected_version, true)
    end

    def link_to_stream(events, stream_name, expected_version)
      add_to_stream(events, stream_name, expected_version, nil)
    end
  
  private

    def add_to_stream(events, stream_name, expected_version, include_global, &block)
      assert_valid_version_for_stream!(stream_name, expected_version)

      events = normalize_to_array(events)
      expected_version = normalize_expected_version(expected_version, stream_name)

      append(events, stream_name, expected_version, include_global, &block)
      
      self
    end

    def append(events, stream_name, expected_version, include_global, &block)
      raise "Not implemented: #{self.class.name}#append"
    end

    def assert_valid_version_for_stream!(stream_name, expected_version)
      raise InvalidExpectedVersion if !expected_version.equal?(:any) && stream_name.eql?(GLOBAL_STREAM)
    end

    def compute_position(expected_version, offset = 0)
      puts "expected_version: #{expected_version.inspect}"
      puts "offset: #{offset.inspect}"
      puts "POSITION_SHIFT: #{POSITION_SHIFT.inspect}"
      unless expected_version.equal?(:any)
        expected_version + offset + POSITION_SHIFT
      end
    end

    def normalize_expected_version(expected_version, stream_name)
      case expected_version
        when Integer, :any
          expected_version
        when :none
          -1
        when :auto
          last_position_for(stream_name) || POSITION_DEFAULT
        else
          raise InvalidExpectedVersion
      end
    end

    def last_position_for(stream_name)
      raise "Not implemented: #{self.class.name}#last_position_for"
    end

    def normalize_to_array(events)
      return events if events.is_a?(Enumerable)
      [events]
    end
  end
end
