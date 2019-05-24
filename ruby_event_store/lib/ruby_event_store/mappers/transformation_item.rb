require 'forwardable'

module RubyEventStore
  module Mappers
    class TransformationItem
      include Enumerable
      extend  Forwardable

      def initialize(h)
        @h = {}
        h.each do |k, v|
          @h[k] = (v)
        end
      end

      def event_id
        fetch(:event_id)
      end

      def metadata
        fetch(:metadata)
      end

      def data
        fetch(:data)
      end

      def event_type
        fetch(:event_type)
      end

      def ==(other_event)
        other_event.instance_of?(self.class) &&
          other_event.to_h.eql?(to_h)
      end
      alias_method :eql?, :==

      def merge(args)
        TransformationItem.new(@h.merge(args))
      end

      def to_h
        @h.dup
      end

      SAFE_HASH_METHODS = [:[], :fetch]
      delegate SAFE_HASH_METHODS => :@h

      private
      private_constant :SAFE_HASH_METHODS
    end
  end
end
