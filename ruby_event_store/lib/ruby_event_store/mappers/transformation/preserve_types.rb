# frozen_string_literal: true

module RubyEventStore
  module Mappers
    module Transformation
      SerializationError = Class.new(ArgumentError)

      class PreserveTypes
        def initialize(type_resolver: ->(type) { type.to_s } )
          @registered_type_serializers = {}
          @type_resolver = type_resolver
        end

        def register(type, serializer:, deserializer:)
          @registered_type_serializers[@type_resolver.(type)] = {
            serializer: serializer,
            deserializer: deserializer
          }
          self
        end

        def dump(record)
          data_types = store_types(record.data)
          metadata_types = store_types(record.metadata)

          Record.new(
            event_id:   record.event_id,
            event_type: record.event_type,
            data:       transform_hash(record.data),
            metadata:   transform_hash(record.metadata)
              .merge(types: {
                data: data_types,
                metadata: metadata_types,
              }),
            timestamp:  record.timestamp,
            valid_at:   record.valid_at,
          )
        end

        def load(record)
          types = record.metadata.delete(:types)
          data_types = types && types[:data]
          metadata_types = types && types[:metadata]
          data = data_types ? restore_types(record.data, data_types) : record.data
          metadata = metadata_types ? restore_types(record.metadata, metadata_types) : record.metadata

          Record.new(
            event_id:   record.event_id,
            event_type: record.event_type,
            data:       data,
            metadata:   metadata,
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

        def transform_hash(argument)
          argument.each_with_object({}) do |(key, value), hash|
            hash[key] = transform_argument(value)
          end
        end

        def transform_argument(argument)
          case argument
          when Hash
            transform_hash(argument)
          when Array
            argument.map{|i| transform_argument(i)}
          else
            serializer_of(argument.class).call(argument)
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
            argument.each_with_index.map{|a,idx| restore_type(a, type.fetch(idx))}
          else
            deserializer_of(type).call(argument)
          end
        end

        def serializer_of(type)
          @registered_type_serializers.dig(@type_resolver.(type), :serializer) || PASS_THROUGH
        end

        def deserializer_of(type)
          @registered_type_serializers.dig(type, :deserializer) || PASS_THROUGH
        end
      end
    end
  end
end
