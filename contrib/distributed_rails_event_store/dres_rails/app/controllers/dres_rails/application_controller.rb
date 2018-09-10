module DresRails
  class ApplicationController < ActionController::Base
    NEWER_PRIVATE_API = RubyEventStore::Specification.instance_method(:initialize).parameters.first.second == :reader

    def index
      spec = build_initial_spec
      spec = spec.from(after).limit(1000)
      events = spec.each.map(&:to_h)
      render json: {
        after: after,
        events: events,
      }
    end

    private

    def build_initial_spec
      repository = Rails.configuration.event_store.instance_variable_get(:@repository)
      mapper = RubyEventStore::Mappers::NullMapper.new
      if NEWER_PRIVATE_API
        RubyEventStore::Specification.new(
          RubyEventStore::SpecificationReader.new(repository, mapper)
        )
      else
        RubyEventStore::Specification.new(repository, mapper)
      end
    end

    def after
      params[:after_event_id] || :head
    end

  end
end