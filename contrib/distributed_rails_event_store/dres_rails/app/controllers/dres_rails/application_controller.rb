module DresRails
  class ApplicationController < ActionController::Base
    def index
      spec   = build_initial_spec
      spec   = spec.limit(1000)
      spec   = spec.from(after) if after
      events = spec.each.map(&:to_h)

      render json: {
        after:  after || "head",
        events: events,
      }
    end

    private

    def build_initial_spec
      repository = Rails.configuration.event_store.instance_variable_get(:@repository)
      mapper     = RubyEventStore::Mappers::NullMapper.new

      RubyEventStore::Specification.new(RubyEventStore::SpecificationReader.new(repository, mapper))
    end

    def after
      params[:after_event_id]
    end

  end
end