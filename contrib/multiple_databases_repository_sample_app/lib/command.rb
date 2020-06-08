require 'dry-struct'

class Command < Dry::Struct::Value
  Invalid = Class.new(StandardError)

  def self.new(*)
    super
  rescue Dry::Struct::Error => doh
    raise Invalid, doh
  end
end
