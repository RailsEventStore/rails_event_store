# frozen_string_literal: true

require "spec_helper"
require "ruby_event_store"
require "ruby_event_store/spec/event_repository_lint"

module RubyEventStore
  module ActiveRecord
    ::RSpec.describe EventRepository do
      helper = SpecHelper.new
      mk_repository = -> { EventRepository.new(serializer: helper.serializer) }

      let(:repository) { mk_repository.call }
      let(:specification) do
        Specification.new(
          SpecificationReader.new(repository, Mappers::Default.new)
        )
      end

      let(:stream) { Stream.new(SecureRandom.uuid) }
      let(:foo) { SRecord.new(event_id: SecureRandom.uuid) }
      let(:bar) { SRecord.new(event_id: SecureRandom.uuid) }
      let(:baz) { SRecord.new(event_id: SecureRandom.uuid) }
      let(:global_to_a) { repository.read(specification.result).to_a }
      let(:stream_to_a) do
        repository.read(specification.stream(stream.name).result).to_a
      end

      around { |example| helper.run_lifecycle { example.run } }

      around do |example|
        previous_logger = ::ActiveRecord::Base.logger
        ::ActiveRecord::Base.logger =
          Logger
            .new(STDOUT)
            .tap do |l|
              l.formatter =
                proc { |severity, datetime, progname, msg| "#{msg}\n" }
            end if ENV.has_key?("VERBOSE")
        example.run
      ensure
        ::ActiveRecord::Base.logger = previous_logger
      end

      specify "no application transaction, event_id conflict" do
        repository.append_to_stream([foo], stream, ExpectedVersion.any)

        expect do
          repository.append_to_stream([bar], stream, ExpectedVersion.any)
          repository.append_to_stream([foo], stream, ExpectedVersion.any)
        end.to raise_error(EventDuplicatedInStream)

        expect(global_to_a).to eq([foo, bar])
        expect(stream_to_a).to eq([foo, bar])
      end

      specify "no application transaction, expected_version conflict" do
        repository.append_to_stream([foo], stream, ExpectedVersion.none)

        expect do
          repository.append_to_stream([bar], stream, ExpectedVersion.any)
          repository.append_to_stream([baz], stream, ExpectedVersion.none)
        end.to raise_error(WrongExpectedEventVersion)

        expect(global_to_a).to eq([foo, bar])
        expect(stream_to_a).to eq([foo, bar])
      end

      specify "application transaction, event_id conflict" do
        repository.append_to_stream([foo], stream, ExpectedVersion.any)

        expect do
          helper.with_transaction do
            repository.append_to_stream([bar], stream, ExpectedVersion.any)
            repository.append_to_stream([foo], stream, ExpectedVersion.any)
          end
        end.to raise_error(EventDuplicatedInStream)

        expect(global_to_a).to eq([foo])
        expect(stream_to_a).to eq([foo])
      end

      specify "application transaction, expected_version conflict" do
        repository.append_to_stream([foo], stream, ExpectedVersion.none)

        expect do
          helper.with_transaction do
            repository.append_to_stream([bar], stream, ExpectedVersion.any)
            repository.append_to_stream([baz], stream, ExpectedVersion.none)
          end
        end.to raise_error(WrongExpectedEventVersion)

        expect(global_to_a).to eq([foo])
        expect(stream_to_a).to eq([foo])
      end

      specify "application transaction, event_id conflict — block rescued" do
        repository.append_to_stream([foo], stream, ExpectedVersion.any)

        helper.with_transaction do
          begin
            repository.append_to_stream([bar], stream, ExpectedVersion.any)
            repository.append_to_stream([foo], stream, ExpectedVersion.any)
          rescue EventDuplicatedInStream
          end
        end

        expect(global_to_a).to eq([foo, bar])
        expect(stream_to_a).to eq([foo, bar])
      end

      specify "application transaction, expected_version conflict — block rescued" do
        repository.append_to_stream([foo], stream, ExpectedVersion.none)

        helper.with_transaction do
          begin
            repository.append_to_stream([bar], stream, ExpectedVersion.any)
            repository.append_to_stream([baz], stream, ExpectedVersion.none)
          rescue WrongExpectedEventVersion
          end
        end

        expect(global_to_a).to eq([foo, bar])
        expect(stream_to_a).to eq([foo, bar])
      end

      specify "application transaction, event_id conflict — append rescued" do
        repository.append_to_stream([foo], stream, ExpectedVersion.any)

        helper.with_transaction do
          repository.append_to_stream([bar], stream, ExpectedVersion.any)
          begin
            repository.append_to_stream([foo], stream, ExpectedVersion.any)
          rescue EventDuplicatedInStream
          end
        end

        expect(global_to_a).to eq([foo, bar])
        expect(stream_to_a).to eq([foo, bar])
      end

      specify "application transaction, expected_version conflict — append rescued" do
        repository.append_to_stream([foo], stream, ExpectedVersion.none)

        helper.with_transaction do
          repository.append_to_stream([bar], stream, ExpectedVersion.any)
          begin
            repository.append_to_stream([baz], stream, ExpectedVersion.none)
          rescue WrongExpectedEventVersion
          end
        end

        expect(global_to_a).to eq([foo, bar])
        expect(stream_to_a).to eq([foo, bar])
      end
    end
  end
end
