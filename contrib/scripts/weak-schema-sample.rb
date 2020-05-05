begin
  require "bundler/inline"
rescue LoadError => e
  $stderr.puts "Bundler version 1.10 or later is required. Please update your Bundler"
  raise e
end

gemfile(true) do
  source "https://rubygems.org"

  gem 'ruby_event_store', '~> 1.0.0'
  gem 'dry-struct'
  gem 'dry-types'
  gem 'minitest'
end

require "ruby_event_store"
require 'time'
require 'json'
require 'dry-struct'
require 'dry-types'
require 'minitest/assertions'

module Types
  include Dry::Types()

  UUID          = Types::Strict::String.constrained(format: /\A[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-4[0-9a-fA-F]{3}-[89abAB][0-9a-fA-F]{3}-[0-9a-fA-F]{12}\z/i)
  Metadata      = Types::Hash.schema(timestamp: Types::Params::DateTime.meta(omittable: true))
end


class Event < Dry::Struct
  transform_keys(&:to_sym)

  def self.new(data: {}, metadata: {}, **rest)
    timestamp = Time.parse(metadata.delete(:timestamp)) rescue nil
    super(rest.merge(data).merge(metadata: metadata.merge(timestamp: timestamp)))
  end

  def self.inherited(klass)
    super
    klass.attribute :metadata, Types.Constructor(RubyEventStore::Metadata).default { RubyEventStore::Metadata.new }
    klass.attribute :event_id, Types::UUID.default { SecureRandom.uuid }
  end

  def to_h
    data = super
    {
      event_id: data.delete(:event_id),
      metadata: data.delete(:metadata),
      data:     data
    }
  end

  def timestamp
    metadata[:timestamp]
  end

  def data
    to_h[:data]
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

class FooEvent < Event
  attribute   :shared,          Types::UUID
  attribute   :different_type,  Types::Coercible::Integer
  attribute   :with_default,    Types::Strict::Integer.optional
  attribute?  :only_in_foo,     Types::Strict::Integer.optional
  def event_type
    'some'
  end
end
class BarEvent < Event
  attribute   :shared,          Types::UUID
  attribute   :different_type,  Types::Coercible::String
  attribute   :with_default,    Types::Constructor(Integer) {|value| Integer(value || 0)}
  attribute?  :only_in_bar,     Types::Strict::Integer.optional
  def event_type
    'some'
  end
end

require 'minitest/autorun'

class TestWeakSchema < MiniTest::Test
  def setup
    store = RubyEventStore::InMemoryRepository.new
    mapper1 = RubyEventStore::Mappers::Default.new(
      serializer: JSON,
      events_class_remapping: {'some' => 'FooEvent'}
    )
    mapper2 = RubyEventStore::Mappers::Default.new(
      serializer: JSON,
      events_class_remapping: {'some' => 'BarEvent'}
    )
    @res1 = RubyEventStore::Client.new(repository: store, mapper: mapper1)
    @res2 = RubyEventStore::Client.new(repository: store, mapper: mapper2)
  end

  def test_foo_can_be_read_as_bar
    foo = FooEvent.new(shared: SecureRandom.uuid, different_type: 123, with_default: nil, only_in_foo: 234)
    @res1.publish(foo)
    assert_instance_of FooEvent, foo
    bar = @res2.read.event(foo.event_id)
    assert_instance_of BarEvent, bar

    assert_equal foo.shared, bar.shared
    assert_equal '123', bar.different_type
    assert_equal 0, bar.with_default
    assert_nil bar.only_in_bar
    refute_includes bar.data.keys, :only_in_foo
  end

  def test_bar_can_be_read_as_foo
    bar = BarEvent.new(shared: SecureRandom.uuid, different_type: '123', with_default: 234, only_in_bar: 345)
    @res2.publish(bar)
    assert_instance_of BarEvent, bar
    foo = @res1.read.event(bar.event_id)
    assert_instance_of FooEvent, foo

    assert_equal bar.shared, foo.shared
    assert_equal 123, foo.different_type
    assert_equal 234, foo.with_default
    assert_nil foo.only_in_foo
    refute_includes foo.data.keys, :only_in_bar
  end
end
