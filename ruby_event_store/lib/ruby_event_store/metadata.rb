# frozen_string_literal: true

require 'date'
require 'time'
require 'forwardable'

module RubyEventStore
  class Metadata
    include Enumerable
    extend  Forwardable

    def initialize(h = self)
      @h = {}
      h.each do |k, v|
        self[k] = (v)
      end
    end

    def [](key)
      raise ArgumentError unless Symbol === key
      @h[key]
    end

    def []=(key, val)
      raise ArgumentError unless allowed_types.any?{|klass| klass === val }
      raise ArgumentError unless Symbol === key
      @h[key]=val
    end

    def each(&block)
      @h.each(&block)
    end

    SAFE_HASH_METHODS = [:<, :<=, :>, :>=, :assoc, :clear, :compact, :compact!,
      :delete, :delete_if, :dig, :each_key, :each_pair,
      :each_value, :empty?, :fetch, :fetch_values,
      :flatten, :has_key?, :has_value?,
      :keep_if, :key, :key?, :keys, :length,
      :rassoc, :reject!, :select!, :shift, :size, :slice,
      :to_proc, :transform_keys, :transform_values,
      :value?, :values, :values_at]

    delegate SAFE_HASH_METHODS => :@h

    private

    def allowed_types
      [String, Integer, Float, Date, Time, TrueClass, FalseClass, nil, Hash, Array]
    end

    private_constant :SAFE_HASH_METHODS
  end
end
