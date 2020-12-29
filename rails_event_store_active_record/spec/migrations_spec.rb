require 'spec_helper'

RSpec.describe "database schema migrations", :integration do
  include SchemaHelper

  specify "migrate from v1.3.0 to master" do
    Gemfile_1_3_0 = <<~EOG
      source 'https://rubygems.org'

      gem 'rails_event_store', '1.3.0'
      gem 'rails',             '6.0.3.4'
      gem 'pg',                '1.2.3'
      gem 'mysql2',            '0.5.3'
      gem 'sqlite3',           '1.4.2'
    EOG

    Gemfile_master = <<~EOG
      source 'https://rubygems.org'

      gem 'ruby_event_store',                path: '../ruby_event_store'
      gem 'rails_event_store_active_record', path: '../rails_event_store_active_record'
      gem 'rails',    '6.0.3.4'
      gem 'pg',       '1.2.3'
      gem 'mysql2',   '0.5.3'
      gem 'sqlite3',  '1.4.2'
    EOG

    event_ids = 10_000.times.map { SecureRandom.uuid }

    validate_migration(Gemfile_1_3_0, Gemfile_master,
      source_template_name: 'create_event_store_events') do
      run_code(<<~EOF, gemfile: Gemfile_1_3_0)
        DummyEvent = Class.new(RubyEventStore::Event)

        client = RubyEventStore::Client.new(repository: RailsEventStoreActiveRecord::EventRepository.new)
        #{event_ids}.each do |event_id|
          client.append(DummyEvent.new(event_id: event_id),
            stream_name: 'some_stream_to_trigger_two_entries_in_streams_table_per_event')
          end
      EOF

      run_migration('created_at_precision')
      run_migration('add_valid_at')
      run_migration('no_global_stream_entries')

      run_code(<<~EOF, gemfile: Gemfile_master)
        DummyEvent = Class.new(RubyEventStore::Event)

        client = RubyEventStore::Client.new(repository: RailsEventStoreActiveRecord::EventRepository.new(serializer: YAML))
        client.append(DummyEvent.new(event_id: 'f5253bb5-9307-4a87-ab2d-c170df2874e6'))
        client.append(DummyEvent.new(event_id: '2ed455ad-a335-40f9-9249-98ad81bdbfa9'),
          stream_name: 'some_stream_to_trigger_two_entries_in_streams_table_per_event')

        raise unless client.read.to_a.map(&:event_id) == #{event_ids} + %w[
          f5253bb5-9307-4a87-ab2d-c170df2874e6
          2ed455ad-a335-40f9-9249-98ad81bdbfa9
        ]

        raise unless client.read
          .stream('some_stream_to_trigger_two_entries_in_streams_table_per_event')
          .to_a.map(&:event_id) == #{event_ids} + %w[
            2ed455ad-a335-40f9-9249-98ad81bdbfa9
          ]
      EOF
    end
  end
end
