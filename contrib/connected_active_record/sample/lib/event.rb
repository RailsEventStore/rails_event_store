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
