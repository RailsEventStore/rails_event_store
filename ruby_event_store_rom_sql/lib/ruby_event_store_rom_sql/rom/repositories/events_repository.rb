module RubyEventStoreRomSql
  module ROM
    module Repositories
      class EventsRepository < ::ROM::Repository[:events]
        SERIALIZED_RECORD_KEYS = %i[event_id data metadata event_type].freeze

        # relations :event_streams
        # commands :create
        struct_namespace Entities

        ### Writer interface

        def create(*tuples)
          events.changeset(:create, map_to_hash(tuples.flatten)).commit
        end
  
        ### Reader interface
  
        def has_event?(event_id)
          events.where(id: event_id).exist?
        end
  
        def fetch(event_id)
          map_to_serialized_record events.fetch(event_id)
        rescue ::ROM::TupleCountMismatchError
          raise RubyEventStore::EventNotFound.new(event_id)
        end
  
        def read_events_forward(stream_name, after: :head, limit: nil)
          stream = forward_for(stream_name)
  
          unless after.equal?(:head)
            stream = stream.where(event_streams[:id] > fetch_stream_id_for(stream_name, after))
          end

          stream = stream.limit(limit) if limit
          stream.map(&method(:map_to_serialized_record))
        end
  
        def read_events_backward(stream_name, before: :head, limit: nil)
          stream = backward_for(stream_name)
          
          unless before.equal?(:head)
            stream = stream.where(event_streams[:id] < fetch_stream_id_for(stream_name, before))
          end

          stream = stream.limit(limit) if limit
          stream.map(&method(:map_to_serialized_record))
        end
  
        def last_stream_event(stream_name)
          map_to_serialized_record backward_for(stream_name).first
        end
  
        def detect_invalid_event_ids(event_ids)
          event_ids - events.where(id: event_ids).pluck(:id)
        end
  
      private

        def fetch_stream_id_for(stream_name, event_id)
          event_streams.where(stream: stream_name, event_id: event_id).limit(1).pluck(:id).first
        end
  
        def forward_for(stream_name)
          events_for(stream_name, :asc)
        end
  
        def backward_for(stream_name)
          events_for(stream_name, :desc)
        end

        def events_for(stream_name, direction)
          order_columns = %i[position id]
          order_columns.delete(:position) if stream_name == RubyEventStore::GLOBAL_STREAM

          events
            .join(event_streams, event_id: :id)
            .where(event_streams[:stream].in(stream_name))
            .order { |r| order_columns.map { |c| r[:event_streams][c].__send__(direction) } }
        end

        def map_to_hash(tuples)
          hashes = Array(tuples).map do |tuple|
            case tuple
            when RubyEventStore::SerializedRecord
              SERIALIZED_RECORD_KEYS.each_with_object({}) do |key, hash|
                hash[key] = tuple.__send__(key)
              end.tap do |hash|
                # Fix for changeset not mapping back to original column
                hash[:id] = hash.delete(:event_id)
              end
            else
              tuple
            end
          end

          tuples.is_a?(Array) ? hashes : hashes.first
        end

        def map_to_serialized_record(record)
          hash = record.to_h
          hash[:event_id] = hash.delete(:id)

          kwargs = hash.select { |key, _| SERIALIZED_RECORD_KEYS.include?(key) }
          RubyEventStore::SerializedRecord.new(**kwargs)
        rescue ArgumentError => ex
          raise unless ex.message =~ /missing keyword/
        end
      end
    end
  end
end
