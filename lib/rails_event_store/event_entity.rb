require 'active_model'

module RailsEventStore
  class EventEntity
    include ::ActiveModel::Model

    attr_accessor :id, :stream, :event_type, :event_id,
                  :metadata, :data, :created_at

    def method_missing(method_name, *args, &block)
      data.send(method_name, *args, &block)
    end

    def respond_to_missing?(method_name, include_private = false)
      data.respond_to?(method_name)
    end

    def data
      @_data ||= OpenStruct.new(@data)
    end
  end
end
