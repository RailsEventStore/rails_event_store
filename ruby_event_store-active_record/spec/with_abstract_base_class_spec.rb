# frozen_string_literal: true

require "spec_helper"
require "ruby_event_store"
require "ruby_event_store/spec/event_repository_lint"

module RubyEventStore
  module ActiveRecord
    ::RSpec.describe WithAbstractBaseClass do
      include SchemaHelper

      specify "Base for event factory models must be an abstract class" do
        NonAbstractClass = Class.new(::ActiveRecord::Base)
        expect { WithAbstractBaseClass.new(NonAbstractClass) }.to raise_error(ArgumentError).with_message(
          "RubyEventStore::ActiveRecord::NonAbstractClass must be an abstract class that inherits from ActiveRecord::Base",
        )
      end

      specify "Base for event factory models could not be the ActiveRecord::Base" do
        expect { WithAbstractBaseClass.new(::ActiveRecord::Base) }.to raise_error(ArgumentError).with_message(
          "ActiveRecord::Base must be an abstract class that inherits from ActiveRecord::Base",
        )
      end

      specify "Base for event factory models must inherit from ActiveRecord::Base" do
        expect { WithAbstractBaseClass.new(Object) }.to raise_error(ArgumentError).with_message(
          "Object must be an abstract class that inherits from ActiveRecord::Base",
        )
      end

      specify "AR classes must have the same instance id" do
        event_klass, stream_klass = WithAbstractBaseClass.new(CustomApplicationRecord).call

        expect(event_klass.name).to match(/^Event_[a-z,0-9]{32}$/)
        expect(stream_klass.name).to match(/^EventInStream_[a-z,0-9]{32}$/)
        expect(event_klass.name[6..-1]).to eq(stream_klass.name[14..-1])
      end

      specify "each factory must generate different AR classes" do
        factory1 = WithAbstractBaseClass.new(CustomApplicationRecord)
        factory2 = WithAbstractBaseClass.new(CustomApplicationRecord)
        event_klass_1, stream_klass_1 = factory1.call
        event_klass_2, stream_klass_2 = factory2.call
        expect(event_klass_1).not_to eq(event_klass_2)
        expect(stream_klass_1).not_to eq(stream_klass_2)
      end

      specify "reading/writting works with base class" do
        begin
          establish_database_connection
          load_database_schema

          repository =
            EventRepository.new(
              model_factory: WithAbstractBaseClass.new(CustomApplicationRecord),
              serializer: Serializers::YAML,
            )
          repository.append_to_stream([event = SRecord.new], Stream.new(GLOBAL_STREAM), ExpectedVersion.any)
          reader = SpecificationReader.new(repository, Mappers::Default.new)
          specification = Specification.new(reader)
          read_event = repository.read(specification.result).first
          expect(read_event).to eq(event)
        ensure
          drop_database
        end
      end

      specify "read from declared tables" do
        begin
          establish_database_connection
          load_database_schema

          repository =
            EventRepository.new(
              model_factory: WithAbstractBaseClass.new(CustomApplicationRecord),
              serializer: Serializers::YAML,
            )
          repository.append_to_stream(
            [event = SRecord.new(event_type: "Dummy")],
            Stream.new("some"),
            ExpectedVersion.any,
          )
          reader = SpecificationReader.new(repository, Mappers::Default.new)

          expect do
            read_event = repository.read(Specification.new(reader).result).first
            expect(read_event).to eq(event)
          end.to match_query(/SELECT.*FROM.*event_store_events.*/)

          expect do
            read_event = repository.read(Specification.new(reader).of_type("Dummy").stream("some").result).first
            expect(read_event).to eq(event)
          end.to match_query(/SELECT.*FROM.*event_store_events_in_streams.*/)
        ensure
          drop_database
        end
      end
    end
  end
end
