require 'forwardable'

module RubyEventStore
  module Mappers
    class TransformationItem
      include Enumerable
      extend  Forwardable

      def initialize(h = self)
        @h = {}
        h.each do |k, v|
          self[k] = (v)
        end
      end

      def event_id
        @h[:event_id]
      end

      def metadata
        @h[:metadata]
      end

      def data
        @h[:data]
      end

      def event_type
        @h[:event_type]
      end

      def ==(other_event)
        other_event.instance_of?(self.class) &&
          other_event.to_h.eql?(to_h)
      end
      alias_method :eql?, :==

      def to_h
        @h
      end

      def merge(args)
        TransformationItem.new(@h.merge(args))
      end

      SAFE_HASH_METHODS = [:[], :[]=]
      delegate SAFE_HASH_METHODS => :@h

      private
      private_constant :SAFE_HASH_METHODS
    end
  end
end
