require 'spec_helper'


RSpec.describe "database schema migrations" do
  include SchemaHelper

  specify "migrate from v0.33.0 to v0.34.0" do
    validate_migration('Gemfile.0_33_0', 'Gemfile.0_34_0',
                       source_template_name: 'migration') do
      run_migration('index_by_event_type')
      run_migration('limit_for_event_id')
    end
  end

  specify "migrate from v0.34.0 to v0.35.0" do
    skip("incompatible version of activerecord-import") if rails_6? && sqlite?

    validate_migration('Gemfile.0_34_0', 'Gemfile.0_35_0',
      source_template_name: 'create_event_store_events') do
      run_code(<<~EOF, gemfile: 'Gemfile.0_34_0')
        DummyEvent = Class.new(RubyEventStore::Event)

        client = RubyEventStore::Client.new(repository: RailsEventStoreActiveRecord::EventRepository.new)
        client.append(DummyEvent.new(event_id: "94b297a3-5a29-4942-9038-3efeceb4d905", data: {
          all: true,
          a: 1,
          text: "text",
        }))
      EOF

      run_migration('binary_data_and_metadata')
      run_code(<<~EOF, gemfile: 'Gemfile.0_35_0')
        DummyEvent = Class.new(RubyEventStore::Event)

        client = RubyEventStore::Client.new(repository: RailsEventStoreActiveRecord::EventRepository.new)
        raise unless client.read.event("94b297a3-5a29-4942-9038-3efeceb4d905").data == {
          all: true,
          a: 1,
          text: "text",
        }
      EOF
    end
  end

  def rails_6?
    Gem::Version.new(ENV['RAILS_VERSION']) >= Gem::Version.new('6.0.0.rc1')
  end

  def sqlite?
    ENV['DATABASE_URL'].start_with?('sqlite')
  end
end
