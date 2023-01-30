# frozen_string_literal: true

require "spec_helper"
require "ruby_event_store"
require "ruby_event_store/spec/event_repository_lint"

module RubyEventStore
  module ActiveRecord
    ::RSpec.describe "PassThrough" do
      helper = SpecHelper.new
      mk_repository = -> { EventRepository.new(serializer: JSON) }

      let(:repository) { mk_repository.call }
      let(:specification) do
        RubyEventStore::Specification.new(
          RubyEventStore::SpecificationReader.new(repository, RubyEventStore::Mappers::NullMapper.new)
        )
      end

      around(:each) { |example| helper.run_lifecycle { example.run } }

      specify do
        repository.append_to_stream(
          [RubyEventStore::SRecord.new(data: { "foo" => "bar" })],
          RubyEventStore::Stream.new("stream"),
          RubyEventStore::ExpectedVersion.auto
        )

        record = repository.read(specification.result).first
        expect(record.data).to eq({ "foo" => "bar" })
        expect(
          ::ActiveRecord::Base
            .connection
            .execute("SELECT data ->> 'foo' as foo FROM event_store_events ORDER BY created_at DESC")
            .first[
            "foo"
          ]
        ).to eq("bar")
      end if ENV["DATABASE_URL"].include?("postgres") && %w[json jsonb].include?(ENV["DATA_TYPE"])

      specify do
        repository.append_to_stream(
          [RubyEventStore::SRecord.new(data: { "foo" => "bar" })],
          RubyEventStore::Stream.new("stream"),
          RubyEventStore::ExpectedVersion.auto
        )

        record = repository.read(specification.result).first
        expect(record.data).to eq({ "foo" => "bar" })
      end
    end
  end
end
