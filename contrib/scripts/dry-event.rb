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
  gem 'rspec'
  gem 'pry'
end

require "ruby_event_store"
require 'time'
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
require_relative '../../support/helpers/rspec_defaults'

module Foo
  class Bar < Event
    event_type 'foo-bar'
    attribute  :id,        Types::Strict::String
    attribute  :coercible, Types::Coercible::Integer.optional
    attribute? :nullable,  Types::Strict::Integer.optional
  end

  RSpec.describe 'dry-event' do
    it_behaves_like :event, ::Event

    it do
      bar = Foo::Bar.new(id: 'xxx', coercible: 123)
      expect(bar.event_type).to eq('foo-bar')
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
  end
end
