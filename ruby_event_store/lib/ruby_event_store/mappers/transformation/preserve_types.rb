# frozen_string_literal: true

module RubyEventStore
  module Mappers
    module Transformation
      class PreserveTypes
        def initialize(type_resolver: ->(type) { type.to_s } )
          @registered_type_serializers = {}
          @type_resolver = type_resolver
        end

        def register(type, serializer:, deserializer:, stored_type: nil)
          @registered_type_serializers[@type_resolver.(type)] = {
            serializer: serializer,
            deserializer: deserializer,
            store_type: stored_type,
          }
          self
        end

        def dump(record)
          data = transform(record.data)
          metadata = transform(record.metadata)
          if (metadata.respond_to?(:[]=))
            metadata[:types] = {
              data: store_type(record.data),
              metadata: store_type(record.metadata),
            }
          end

          Record.new(
            event_id:   record.event_id,
            event_type: record.event_type,
            data:       data,
            metadata:   metadata,
            timestamp:  record.timestamp,
            valid_at:   record.valid_at,
          )
        end

        def load(record)
          types = record.metadata.delete(:types) rescue nil
          data_types = types&.fetch(:data, nil)
          metadata_types = types&.fetch(:metadata, nil)
          data = data_types ? restore_type(record.data, data_types) : record.data
          metadata = metadata_types ? restore_type(record.metadata, metadata_types) : record.metadata

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
        PASS_THROUGH = ->(v) { v }

        def transform_hash(argument)
          argument.each_with_object({}) do |(key, value), hash|
            hash[transform(key)] = transform(value)
          end
        end

        def transform(argument)
          case argument
          when Hash
            transform_hash(argument)
          when Array
            argument.map{|i| transform(i)}
          else
            serializer_of(argument.class).call(argument)
          end
        end

        def store_types(argument)
          argument.each_with_object({}) do |(key, value), hash|
            hash[transform(key)] = [store_type(key), store_type(value)]
          end
        end

        def store_type(argument)
          case argument
          when Hash
            store_types(argument)
          when Array
            argument.map { |i| store_type(i) }
          else
            store_type_of(argument).call(argument)
          end
        end

        def restore_types(argument, types)
          argument.each_with_object({}) do |(key, value), hash|
            key_type, value_type = types.fetch(key.to_sym) { types.fetch(key.to_s) }
            restored_key = restore_type(key, key_type)
            hash[restored_key] = restore_type(value, value_type)
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

        def store_type_of(argument)
          @registered_type_serializers.dig(@type_resolver.(argument.class), :store_type) || -> (argument) { argument.class.name }
        end
      end
    end
  end
end
