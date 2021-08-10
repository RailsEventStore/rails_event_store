require 'spec_helper'
require 'json'

module RubyEventStore
  module Mappers
    module Transformation
      RSpec.describe PreserveTypes do
        let(:time)  { Time.now.utc }
        let(:iso_time) { time.iso8601(9) }
        let(:uuid)  { SecureRandom.uuid }
        let(:record)  {
          Record.new(
            event_id:   uuid,
            metadata:   {
              some: 'meta',
              any: :symbol,
            },
            data:       {
              'any' => 'data',
              at_some: time,
              nested: {
                another_time: time,
                array: [
                  123,
                  {
                    'deeply_nested' => {
                      time: time,
                      'and' => 'something'
                    }
                  },
                  { and_another_time: time },
                ],
              }
            },
            event_type: 'TestEvent',
            timestamp:  time,
            valid_at:   time
          )
        }
        let(:dump_of_record)  {
          Record.new(
            event_id:   uuid,
            metadata:   {
              some: 'meta',
              any: 'symbol',
              types: {
                data: {
                  'any' => 'String',
                  'at_some' => 'Time',
                  'nested' => {
                    'another_time' => 'Time',
                    'array' => [
                      'Integer',
                      { 'deeply_nested' => {
                          'time' => 'Time',
                          'and' => 'String',
                          '_res_symbol_keys' => ['time']
                        },
                        '_res_symbol_keys' => []
                      },
                      {
                        'and_another_time' => 'Time',
                        '_res_symbol_keys' => ['and_another_time']
                      },
                    ],
                    '_res_symbol_keys' => ['another_time', 'array']
                  },
                  '_res_symbol_keys' => ['at_some', 'nested']
                },
                metadata: {
                  'some' => 'String',
                  'any' => 'Symbol',
                  '_res_symbol_keys' => ['some', 'any']
                }
              },
            },
            data:       {
              'any' => 'data',
              at_some: iso_time,
              nested: {
                another_time: iso_time,
                array: [
                  123,
                  {
                    'deeply_nested' => {
                      time: iso_time,
                      'and' => 'something'
                    }
                  },
                  { and_another_time: iso_time },
                ],
              }
            },
            event_type: 'TestEvent',
            timestamp:  time,
            valid_at:   time
          )
        }

        let(:json_record) {
          Record.new(
            event_id: uuid,
            metadata: TransformKeys.symbolize(JSON.parse(JSON.dump(dump_of_record.metadata))),
            data: JSON.parse(JSON.dump(dump_of_record.data)),
            event_type: 'TestEvent',
            timestamp:  time,
            valid_at:   time
          )
        }

        let(:transformation) {
          PreserveTypes.new
            .register(
              Time,
              serializer: ->(v) { v.iso8601(9) },
              deserializer: ->(v) { Time.iso8601(v) },
            )
            .register(
              Symbol,
              serializer: ->(v) { v.to_s },
              deserializer: ->(v) { v.to_sym },
            )
        }

        specify "#dump" do
          result = transformation.dump(record)
          expect(result).to eq(dump_of_record)
          expect(result.metadata).to eq(dump_of_record.metadata)
        end

        specify "#load" do
          result = transformation.load(json_record)
          expect(result).to eq(record)
          expect(result.metadata).to eq({
            some: 'meta',
            any: :symbol,
          })
        end

        specify "no op when no types" do
          record_without_types = Record.new(
            event_id: uuid,
            metadata: {"some" => "meta", "any" => "symbol"},
            data: {"some" => "value"},
            event_type: 'TestEvent',
            timestamp:  time,
            valid_at:   time
          )

          result = transformation.load(record_without_types)
          expect(result).to eq(record_without_types)
          expect(result.metadata).to eq({"some" => "meta", "any" => "symbol"})
        end

        specify "no data transform when no data types" do
          record_without_types = Record.new(
            event_id: uuid,
            metadata: {"some" => "meta", "any" => "symbol",
              types: {
                metadata: {
                  some: "String",
                  any: "Symbol",
                  "_res_symbol_keys": ["some"]
                }
              }
            },
            data: {"some" => "value"},
            event_type: 'TestEvent',
            timestamp:  time,
            valid_at:   time
          )

          result = transformation.load(record_without_types)
          expect(result.data).to eq({"some" => "value"})
          expect(result.metadata).to eq({some: "meta", "any" => :symbol})
        end

        specify "no metadata transform when no metadata types" do
          record_without_types = Record.new(
            event_id: uuid,
            metadata: {"some" => "meta", "any" => "symbol",
              types: {
                data: {
                  some: "String",
                  "_res_symbol_keys": ["some"]
                }
              }
            },
            data: {"some" => "value"},
            event_type: 'TestEvent',
            timestamp:  time,
            valid_at:   time
          )

          result = transformation.load(record_without_types)
          expect(result.data).to eq({some: "value"})
          expect(result.metadata).to eq({"some" => "meta", "any" => "symbol"})
        end

        specify "fail for reserved keys" do
          invalid = Record.new(
            event_id:   uuid,
            metadata:   record.metadata,
            data:       record.data.merge('_res_symbol_keys' => "not allowed"),
            event_type: 'TestEvent',
            timestamp:  time,
            valid_at:   time
          )
          expect {
            transformation.dump(invalid)
          }.to raise_error(SerializationError)
            .with_message("Can't serialize a Hash with reserved key \"_res_symbol_keys\"")
        end

        specify "fail for invalid keys" do
          key = Object.new
          expect(key).to receive(:inspect).and_return("Doh")
          invalid = Record.new(
            event_id:   uuid,
            metadata:   record.metadata,
            data:       record.data.merge(key => "not allowed"),
            event_type: 'TestEvent',
            timestamp:  time,
            valid_at:   time
          )
          expect {
            transformation.dump(invalid)
          }.to raise_error(SerializationError)
            .with_message("Only string and symbol hash keys may be serialized, but Doh is a Object")
        end

        specify "#dump - no changes if data or metadata are not Hash" do
          record = Record.new(
            event_id:   uuid,
            metadata:   metadata = Object.new,
            data:       data = Object.new,
            event_type: 'TestEvent',
            timestamp:  time,
            valid_at:   time
          )

          result = transformation.dump(record)
          expect(result.data).to eq(data)
          expect(result.metadata).to eq(metadata)
        end

        specify "#load - no changes if data or metadata are not Hash" do
          record = Record.new(
            event_id:   uuid,
            metadata:   metadata = Object.new,
            data:       data = Object.new,
            event_type: 'TestEvent',
            timestamp:  time,
            valid_at:   time
          )

          result = transformation.load(record)
          expect(result.data).to eq(data)
          expect(result.metadata).to eq(metadata)
        end

        specify "#dump - works with Metadata object" do
          record_with_meta = Record.new(
            event_id:   uuid,
            metadata:   metadata = RubyEventStore::Metadata.new({some: 'meta'}),
            data:       {some: 'value'},
            event_type: 'TestEvent',
            timestamp:  time,
            valid_at:   time
          )

          result = transformation.dump(record_with_meta)
          expect(result.data).to eq({some: 'value'})
          expect(result.metadata).to be_a(RubyEventStore::Metadata)
          expect(result.metadata).to eq(metadata)
          expect(result.metadata.to_h).to eq({
            some: 'meta',
            types: {
              data: {
                'some' => 'String',
                '_res_symbol_keys' => ['some'],
              },
              metadata: 'RubyEventStore::Metadata',
            }
          })
        end

        specify "#load - works with Metadata object" do
          record_with_meta = Record.new(
            event_id:   uuid,
            metadata:   metadata = RubyEventStore::Metadata.new({
              some: 'meta',
              types: {
                data: {
                  some: 'String',
                  _res_symbol_keys: ['some'],
                },
                metadata: 'RubyEventStore::Metadata',
              }
            }),
            data:       {"some" => "value"},
            event_type: 'TestEvent',
            timestamp:  time,
            valid_at:   time
          )

          result = transformation.load(record_with_meta)
          expect(result.data).to eq({some: 'value'})
          expect(result.metadata).to be_a(RubyEventStore::Metadata)
          expect(result.metadata).to eq(metadata)
          expect(result.metadata.to_h).to eq({some: 'meta'})
        end

        specify "#dump - works with serializable objects" do
          record = Record.new(
            event_id:   uuid,
            metadata:   {},
            data:       time,
            event_type: 'TestEvent',
            timestamp:  time,
            valid_at:   time
          )

          result = transformation.dump(record)
          expect(result.data).to eq(time.iso8601(9))
          expect(result.metadata).to eq({
            types: {
              data: 'Time',
              metadata: {"_res_symbol_keys"=>[]},
            }
          })
        end

        specify "#load - no changes if data or metadata are not Hash" do
          record = Record.new(
            event_id:   uuid,
            metadata:   {
              types: {
                data: 'Symbol',
                metadata: {"_res_symbol_keys"=>[]},
              }
            },
            data:       :any_given_symbol,
            event_type: 'TestEvent',
            timestamp:  time,
            valid_at:   time
          )

          result = transformation.load(record)
          expect(result.data).to eq(:any_given_symbol)
          expect(result.metadata).to eq({})
        end
      end
    end
  end
end
