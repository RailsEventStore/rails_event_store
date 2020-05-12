begin
  require "bundler/inline"
rescue LoadError => e
  $stderr.puts "Bundler version 1.10 or later is required. Please update your Bundler"
  raise e
end

gemfile(true) do
  source "https://rubygems.org"

  gem 'ruby_event_store', path: File.join(__dir__, '../../ruby_event_store')
  gem 'rails_event_store-rspec', path: File.join(__dir__, '../../rails_event_store-rspec')
  gem 'dry-struct'
  gem 'dry-types'
  gem 'rspec'
  gem 'pry'
end

require "ruby_event_store"
require 'time'
require 'json'
require 'dry-struct'
require 'dry-types'
require 'rspec/core'

module Types
  include Dry::Types()

  EventId   = Types::Coercible::String.default { SecureRandom.uuid }
  Metadata  = Types.Constructor(RubyEventStore::Metadata) { |value| RubyEventStore::Metadata.new(value.to_h) }.default { RubyEventStore::Metadata.new }
end


class Event < Dry::Struct
  transform_keys(&:to_sym)

  attribute :event_id, Types::EventId
  attribute :metadata, Types::Metadata
  alias :message_id :event_id

  def self.new(data: {}, metadata: {}, **args)
    super(args.merge(data).merge(metadata: metadata))
  end

  def self.inherited(klass)
    super
    klass.define_singleton_method(:event_type) do |value|
      klass.define_method(:event_type) do
        value
      end
    end
  end

  def timestamp
    metadata[:timestamp] && Time.parse(metadata[:timestamp])
  end

  def data
    to_h.reject{|k,_| [:event_id, :metadata].include?(k) }
  end

  def event_type
    self.class.name
  end

  def ==(other_event)
    other_event.instance_of?(self.class) &&
      other_event.event_id.eql?(event_id) &&
      other_event.data.eql?(data)
  end

  alias_method :eql?, :==
end

require 'ruby_event_store/spec/event_lint'

RSpec.configure do |config|
  config.mock_with :rspec do |mocks|
    mocks.verify_partial_doubles = true
  end
  config.disable_monkey_patching!

  config.order = :random
  Kernel.srand config.seed
end

module Foo
  class Bar < Event
    event_type 'foo-bar'
    attribute  :id,        Types::Strict::String
    attribute  :coercible, Types::Coercible::Integer.optional
    attribute? :nullable,  Types::Strict::Integer.optional
  end
  class Baz < Event
    attribute  :id,        Types::Strict::String
  end

  RSpec.describe 'dry-event' do
    it_behaves_like :event, ::Event, {}, RubyEventStore::Metadata::new

    it do
      bar = Foo::Bar.new(id: 'xxx', coercible: 123)
      expect(bar.event_type).to eq('foo-bar')

      baz = Foo::Baz.new(id: 'xxx')
      expect(baz.event_type).to eq('Foo::Baz')
    end

    it do
      uuid = SecureRandom.uuid
      bar = Foo::Bar.new(id: uuid, coercible: '123', nullable: 234)
      expect(bar.data).to eq({ id: uuid, coercible: 123, nullable: 234 })
    end

    it do
      uuid = SecureRandom.uuid
      bar = Foo::Bar.new(id: uuid, coercible: '123')
      expect(bar.id).to eq(uuid)
      expect(bar.coercible).to eq(123)
      expect(bar.nullable).to be_nil
    end

    it do
      uuid = SecureRandom.uuid
      bar = Foo::Bar.new(id: uuid, coercible: nil, nullable: 123)
      expect(bar.id).to eq(uuid)
      expect(bar.coercible).to be_nil
      expect(bar.nullable).to eq(123)
    end

    it do
      res = RubyEventStore::Client.new(
        mapper: RubyEventStore::Mappers::Default.new(
          serializer: JSON,
          events_class_remapping: {
            'foo-bar' => 'Foo::Bar'
          }
        ),
        repository: RubyEventStore::InMemoryRepository.new
      )
      uuid = SecureRandom.uuid
      bar = Foo::Bar.new(id: uuid, coercible: nil, nullable: 123)
      res.publish(bar)
      expect(res).to have_published(
        an_event(Foo::Bar).with_data(
          id: uuid,
          coercible: nil,
          nullable: 123,
        ).strict
      )
    end
  end
end
