# frozen_string_literal: true

module DresRails
  class ApplicationController < ActionController::Base
    def index
      spec = build_initial_spec
      spec = spec.limit(1000)
      spec = spec.from(after) if after
      records = repository.read(spec.result).map(&:to_h)

      render json: { after: after || :head, events: records }
    end

    private

    def repository
      RubyEventStore::ActiveRecord::PgLinearizedEventRepository.new(serializer: RubyEventStore::NULL)
    end

    def build_initial_spec
      RubyEventStore::Specification.new(
        RubyEventStore::SpecificationReader.new(repository, RubyEventStore::Mappers::Default.new),
      )
    end

    def after
      params[:after_event_id]
    end
  end
end
