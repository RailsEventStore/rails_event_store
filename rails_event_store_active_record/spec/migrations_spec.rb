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

  specify "migrate from v1.1.1 to master" do
    validate_migration('Gemfile.1_1_1', 'Gemfile.master',
      source_template_name: 'create_event_store_events') do
      run_code(<<~EOF, gemfile: 'Gemfile.1_1_1')
        DummyEvent = Class.new(RubyEventStore::Event)

        client = RubyEventStore::Client.new(repository: RailsEventStoreActiveRecord::EventRepository.new)
        %w[
          96c920b1-cdd0-40f4-907c-861b9fff7d02
          56404f79-0ba0-4aa0-8524-dc3436368ca0
          6a54dd21-f9d8-4857-a195-f5588d9e406c
          0e50a9cd-f981-4e39-93d5-697fc7285b98
          d85589bc-b993-41d4-812f-fc631d9185d5
          96bdacda-77dd-4d7d-973d-cbdaa5842855
          94688199-e6b7-4180-bf8e-825b6808e6cc
          68fab040-741e-4bc2-9cca-5b8855b0ca19
          ab60114c-011d-4d58-ab31-7ba65d99975e
          868cac42-3d19-4b39-84e8-cd32d65c2445
        ].map.with_index do |event_id, idx|
          client.append(DummyEvent.new(event_id: event_id),
            stream_name: 'some_stream_to_trigger_two_entries_in_streams_table_per_event')
          end
      EOF

      run_migration('created_at_precision')
      run_migration('no_global_stream_entries')
      run_migration('add_valid_at')

      run_code(<<~EOF, gemfile: 'Gemfile.master')
        DummyEvent = Class.new(RubyEventStore::Event)

        client = RubyEventStore::Client.new(repository: RailsEventStoreActiveRecord::EventRepository.new(serializer: YAML))
        client.append(DummyEvent.new(event_id: 'f5253bb5-9307-4a87-ab2d-c170df2874e6'))
        client.append(DummyEvent.new(event_id: '2ed455ad-a335-40f9-9249-98ad81bdbfa9'),
          stream_name: 'some_stream_to_trigger_two_entries_in_streams_table_per_event')

        raise unless client.read.to_a.map(&:event_id) == %w[
          96c920b1-cdd0-40f4-907c-861b9fff7d02
          56404f79-0ba0-4aa0-8524-dc3436368ca0
          6a54dd21-f9d8-4857-a195-f5588d9e406c
          0e50a9cd-f981-4e39-93d5-697fc7285b98
          d85589bc-b993-41d4-812f-fc631d9185d5
          96bdacda-77dd-4d7d-973d-cbdaa5842855
          94688199-e6b7-4180-bf8e-825b6808e6cc
          68fab040-741e-4bc2-9cca-5b8855b0ca19
          ab60114c-011d-4d58-ab31-7ba65d99975e
          868cac42-3d19-4b39-84e8-cd32d65c2445
          f5253bb5-9307-4a87-ab2d-c170df2874e6
          2ed455ad-a335-40f9-9249-98ad81bdbfa9
        ]

        raise unless client.read
          .stream('some_stream_to_trigger_two_entries_in_streams_table_per_event')
          .to_a.map(&:event_id) == %w[
          96c920b1-cdd0-40f4-907c-861b9fff7d02
          56404f79-0ba0-4aa0-8524-dc3436368ca0
          6a54dd21-f9d8-4857-a195-f5588d9e406c
          0e50a9cd-f981-4e39-93d5-697fc7285b98
          d85589bc-b993-41d4-812f-fc631d9185d5
          96bdacda-77dd-4d7d-973d-cbdaa5842855
          94688199-e6b7-4180-bf8e-825b6808e6cc
          68fab040-741e-4bc2-9cca-5b8855b0ca19
          ab60114c-011d-4d58-ab31-7ba65d99975e
          868cac42-3d19-4b39-84e8-cd32d65c2445
          2ed455ad-a335-40f9-9249-98ad81bdbfa9
        ]
      EOF
    end
  end

  def rails_6?
    Gem::Version.new(ENV['RAILS_VERSION']) >= Gem::Version.new('6.0.0')
  end

  def sqlite?
    ENV['DATABASE_URL'].start_with?('sqlite')
  end
end
