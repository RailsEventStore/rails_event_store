# frozen_string_literal: true

module RubyEventStore
  module Mappers
    module Transformation
      SerializationError = Class.new(ArgumentError)

      class PreserveTypes
        def initialize
          @registered_type_serializers = {}
        end

        def register(type, serializer: PASS_THROUGH, deserializer: PASS_THROUGH)
          @registered_type_serializers[type.to_s] = {
            serializer: serializer,
            deserializer: deserializer
          }
          self
        end

        def dump(record)
          types = store_types(record.data)

          Record.new(
            event_id:   record.event_id,
            event_type: record.event_type,
            data:       transform_data(record.data),
            metadata:   record.metadata.merge(types: types),
            timestamp:  record.timestamp,
            valid_at:   record.valid_at,
          )
        end

        def load(record)
          types = record.metadata.delete(:types)
          data = types ? restore_types(record.data, types) : record.data

          Record.new(
            event_id:   record.event_id,
            event_type: record.event_type,
            data:       data,
            metadata:   record.metadata,
            timestamp:  record.timestamp,
            valid_at:   record.valid_at,
          )
        end

        private

        SYMBOL_KEYS_KEY = '_res_symbol_keys'
        RESERVED_KEYS = [
          SYMBOL_KEYS_KEY, SYMBOL_KEYS_KEY.to_sym,
        ]
        PASS_THROUGH = ->(v) { v }

        def transform_data(argument)
          argument.each_with_object({}) do |(key, value), hash|
            hash[key] = transform_argument(value)
          end
        end

        def transform_argument(argument)
          case argument
          when Hash
            transform_data(argument)
          when Array
            argument.map{|i| transform_argument(i)}
          else
            serializer_of(argument.class.name).call(argument)
          end
        end

        def store_types(argument)
          argument.each_with_object({}) do |(key, value), hash|
            hash[serialize_hash_key(key)] = store_type(value)
          end
          .merge(SYMBOL_KEYS_KEY => argument.each_key.grep(Symbol).map!(&:to_s))
        end

        def store_type(argument)
          case argument
          when Hash
            store_types(argument)
          when Array
            argument.map{|i| store_type(i)}
          else
            argument.class.name
          end
        end

        def serialize_hash_key(key)
          case key
          when *RESERVED_KEYS
            raise SerializationError.new("Can't serialize a Hash with reserved key #{key.inspect}")
          when String, Symbol
            key.to_s
          else
            raise SerializationError.new("Only string and symbol hash keys may be serialized, but #{key.inspect} is a #{key.class}")
          end
        end

        def restore_types(argument, types)
          symbol_keys = types.delete(SYMBOL_KEYS_KEY.to_sym)
          argument.each_with_object({}) do |(key, value), hash|
            type = types.fetch(key.to_sym)
            restored_key = symbol_keys.include?(key) ? key.to_sym : key
            hash[restored_key] = restore_type(value, type)
          end
        end

        def restore_type(argument, type)
          case argument
          when Hash
            restore_types(argument, type)
          when Array
            argument.each_with_index.map{|a,idx| restore_type(a, type[idx])}
          else
            deserializer_of(type).call(argument)
          end
        end

        def serializer_of(type)
          @registered_type_serializers.dig(type, :serializer) || PASS_THROUGH
        end

        def deserializer_of(type)
          @registered_type_serializers.dig(type, :deserializer) || PASS_THROUGH
        end
      end
    end
  end
end
