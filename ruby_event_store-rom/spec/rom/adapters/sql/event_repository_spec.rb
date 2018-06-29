require 'spec_helper'
require 'ruby_event_store/rom/sql'
require 'ruby_event_store/spec/rom/event_repository_lint'

module RubyEventStore::ROM
  RSpec.describe EventRepository do
    let(:rom_helper) { SQL::SpecHelper.new }

    it_behaves_like :rom_event_repository, EventRepository

    # TODO: Port from AR to ROM
    xspecify "using preload()" do
      repository = repository
      repository.append_to_stream([
        SRecord.new,
        SRecord.new,
      ], default_stream, RubyEventStore::ExpectedVersion.auto)
      c1 = count_queries{ repository.read(RubyEventStore::Specification.new(repository).from(:head).limit(2).result) }
      expect(c1).to eq(2)

      c2 = count_queries{ repository.read(RubyEventStore::Specification.new(repository).from(:head).limit(2).backward.result) }
      expect(c2).to eq(2)

      c3 = count_queries{ repository.read(RubyEventStore::Specification.new(repository).stream("stream").result) }
      expect(c3).to eq(2)

      c4 = count_queries{ repository.read(RubyEventStore::Specification.new(repository).stream("stream").backward.result) }
      expect(c4).to eq(2)

      c5 = count_queries{ repository.read(RubyEventStore::Specification.new(repository).stream("stream").from(:head).limit(2).result) }
      expect(c5).to eq(2)

      c6 = count_queries{ repository.read(RubyEventStore::Specification.new(repository).stream("stream").from(:head).limit(2).backward.result) }
      expect(c6).to eq(2)
    end
  end
end
