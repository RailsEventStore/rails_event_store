# frozen_string_literal: true

require "active_record"

module RubyEventStore
  module ActiveRecord
    module SkipJsonSerialization
      extend ActiveSupport::Concern

      skip_json_serialization = ->(cast_type) do
        %i[json jsonb].include?(cast_type.type) ? ActiveModel::Type::Value.new : cast_type
      end

      if ::ActiveRecord.version >= Gem::Version.new("7.2.0")
        class_methods { define_method(:hook_attribute_type) { |name, cast_type| skip_json_serialization[cast_type] } }
      else
        included do
          attribute :data, skip_json_serialization
          attribute :metadata, skip_json_serialization
        end
      end
    end
  end
end
