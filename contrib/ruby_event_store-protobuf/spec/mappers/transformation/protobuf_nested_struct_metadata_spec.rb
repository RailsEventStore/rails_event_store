require 'spec_helper'

module RubyEventStore
  module Mappers
    module Transformation
      RSpec.describe ProtobufNestedStructMetadata do
        include ProtobufHelper
        before(:each) { require_protobuf_dependencies }

        let(:metadata) { {
          one: 1,
          two: 2.0,
          three: true,
          four: Date.new(2018, 4, 17),
          five: "five",
          six: Time.utc(2018, 12, 13, 11 ),
          seven: true,
          eight: false,
          nein: nil,
          ten: {some: 'hash', with: {nested: 'values'}},
          eleven: [1,2,3],
        } }
        let(:uuid) { SecureRandom.uuid }
        let(:record) { Record.new(event_id: uuid, event_type: 'SomeEvent', data: "anything", metadata: metadata, timestamp: Time.new.utc, valid_at: Time.new.utc) }

        specify "#initialize requires protobuf_nested_struct" do
          p = ProtobufNestedStructMetadata.allocate
          def p.require(_name)
            raise LoadError
          end
          expect do
            p.send(:initialize)
          end.to raise_error(LoadError, "cannot load such file -- protobuf_nested_struct. Add protobuf_nested_struct gem to Gemfile")
        end

        specify "#dump" do
          dump = ProtobufNestedStructMetadata.new.dump(record)
          expect(dump.event_id).to eq(record.event_id)
          expect(dump.data).not_to be_empty
          expect(dump.metadata).not_to be_empty
        end

        specify "#load" do
          dump = ProtobufNestedStructMetadata.new.dump(record)
          load = ProtobufNestedStructMetadata.new.load(dump)
          expect(load).to eq(record)
        end
      end
    end
  end
end
