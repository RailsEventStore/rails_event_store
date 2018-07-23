module DresRails
  class ApplicationController < ActionController::Base
    def index
      spec = RubyEventStore::Specification.new(
        Rails.configuration.event_store.instance_variable_get(:@repository),
        RubyEventStore::Mappers::NullMapper.new,
      )
      spec = spec.from(after).limit(1000)
      events = spec.each.map(&:to_h)
      render json: {
        after: after,
        events: events,
      }
    end

    private

    def after
      params[:after_event_id] || :head
    end

  end
end