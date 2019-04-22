require 'spec_helper'

module RubyEventStore
  module Mappers
    RSpec.describe ProtobufNestedStructMetadataMapper do
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
      let(:item) { TransformationItem.new(event_id: uuid, data: "anything", metadata: metadata) }

      specify "#initialize requires protobuf_nested_struct" do
        p = ProtobufNestedStructMetadataMapper.allocate
        def p.require(_name)
          raise LoadError
        end
        expect do
          p.send(:initialize)
        end.to raise_error(LoadError, "cannot load such file -- protobuf_nested_struct. Add protobuf_nested_struct gem to Gemfile")
      end

      specify "#dump" do
        dump = ProtobufNestedStructMetadataMapper.new.dump(item)
        expect(dump.event_id).to eq(item.event_id)
        expect(dump.data).not_to be_empty
        expect(dump.metadata).not_to be_empty
      end

      specify "#load" do
        dump = ProtobufNestedStructMetadataMapper.new.dump(item)
        load = ProtobufNestedStructMetadataMapper.new.load(dump)
        expect(load).to eq(item)
      end
    end
  end
end
