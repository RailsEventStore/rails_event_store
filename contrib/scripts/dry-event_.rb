require "bundler/inline"

gemfile do
  source "https://rubygems.org"

  gem 'ruby_event_store',       path: File.join(__dir__, '../../ruby_event_store')
  gem 'ruby_event_store-rspec', path: File.join(__dir__, '../../ruby_event_store-rspec')
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
end

require 'forwardable'

class Event < RubyEventStore::Event
  class << self
    def inherited(klass)
      super
      klass.define_singleton_method(:event_type) do |value|
        klass.define_method(:event_type) do
          value
        end
      end
    end

    def schema(&block)
      @schema ||= begin
        Class.new(Dry::Struct).tap do |s|
          s.transform_keys(&:to_sym)
          s.instance_exec(&block) if block_given?
        end
      end
    end
  end

  def initialize(event_id: SecureRandom.uuid, metadata: nil, data: {})
    super
    @data = self.class.schema.new(data)
  end

  def data
    @data.to_h
  end
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
    event_type "foo-bar"
    schema do
      attribute  :id,        Types::Strict::String
      attribute  :coercible, Types::Coercible::Integer.optional
      attribute? :nullable,  Types::Strict::Integer.optional
    end
  end
  class Baz < Event
    schema do
      attribute :id, Types::Strict::String
    end
  end

  RSpec.describe 'dry-event' do
    it_behaves_like :event, Class.new(Event) { event_type 'dummy' }, {}, RubyEventStore::Metadata.new

    it do
      bar = Foo::Bar.new(data: { id: 'xxx', coercible: 123 })
      expect(bar.event_type).to eq('foo-bar')

      baz = Foo::Baz.new(data: { id: 'xxx' })
      expect(baz.event_type).to eq('Foo::Baz')
    end

    it do
      uuid = SecureRandom.uuid
      bar = Foo::Bar.new(data: { id: uuid, coercible: '123', nullable: 234 })
      expect(bar.data).to eq({ id: uuid, coercible: 123, nullable: 234 })
    end

    it do
      uuid = SecureRandom.uuid
      bar = Foo::Bar.new(data: { id: uuid, coercible: '123' })
      expect(bar.data[:id]).to eq(uuid)
      expect(bar.data[:coercible]).to eq(123)
      expect(bar.data[:nullable]).to be_nil
    end

    it do
      uuid = SecureRandom.uuid
      bar = Foo::Bar.new(data: { id: uuid, coercible: nil, nullable: 123 })
      expect(bar.data[:id]).to eq(uuid)
      expect(bar.data[:coercible]).to be_nil
      expect(bar.data[:nullable]).to eq(123)
    end

    it do
      res = RubyEventStore::Client.new(
        mapper: RubyEventStore::Mappers::Default.new(
          events_class_remapping: {
            'foo-bar' => 'Foo::Bar'
          }
        ),
        repository: RubyEventStore::InMemoryRepository.new(serializer: JSON)
      )
      uuid = SecureRandom.uuid
      bar = Foo::Bar.new(data: { id: uuid, coercible: nil, nullable: 123 })
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
