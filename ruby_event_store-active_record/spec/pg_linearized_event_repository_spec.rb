require "spec_helper"
require "ruby_event_store"
require "ruby_event_store/spec/event_repository_lint"

module RubyEventStore
  module ActiveRecord
    RSpec.describe PgLinearizedEventRepository do
      helper = SpecHelper.new
      mk_repository = -> { PgLinearizedEventRepository.new(serializer: RubyEventStore::Serializers::YAML) }

      it_behaves_like :event_repository, mk_repository, helper

      let(:repository) { mk_repository.call }

      around(:each) { |example| helper.run_lifecycle { example.run } }

      specify "linearized by lock" do
        begin
          timeout = 2
          exchanger = Concurrent::Exchanger.new
          t =
            Thread.new do
              ::ActiveRecord::Base.transaction do
                append_an_event_to_repo
                exchanger.exchange!("locked", timeout)
                exchanger.exchange!("unlocked", timeout)
              end
            end

          exchanger.exchange!("locked", timeout)
          ::ActiveRecord::Base.transaction do
            execute("SET LOCAL lock_timeout = '1s';")
            expect { append_an_event_to_repo }.to raise_error(::ActiveRecord::LockWaitTimeout)
          end
          exchanger.exchange!("unlocked", timeout)

          expect { append_an_event_to_repo }.not_to raise_error
        ensure
          t.join
        end
      end

      specify "can publish multiple times" do
        helper.with_transaction do
          expect do
            append_an_event_to_repo
            append_an_event_to_repo
            append_an_event_to_repo
          end.not_to raise_error
        end
      end

      specify "can publish multiple events" do
        helper.with_transaction do
          expect do
            repository.append_to_stream(
              [RubyEventStore::SRecord.new, RubyEventStore::SRecord.new],
              RubyEventStore::Stream.new(RubyEventStore::GLOBAL_STREAM),
              RubyEventStore::ExpectedVersion.any
            )
          end.not_to raise_error
        end
      end

      private

      def execute(sql)
        ::ActiveRecord::Base.connection.execute(sql).each.to_a
      end

      def append_an_event_to_repo
        repository.append_to_stream(
          [RubyEventStore::SRecord.new],
          RubyEventStore::Stream.new(RubyEventStore::GLOBAL_STREAM),
          RubyEventStore::ExpectedVersion.any
        )
      end
    end if ENV["DATABASE_URL"].include?("postgres")
  end
end
