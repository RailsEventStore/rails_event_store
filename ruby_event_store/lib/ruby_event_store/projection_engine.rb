require_relative "projection"

module RubyEventStore
  class ProjectionEngine
    attr_reader :repository

    def initialize(repository)
      @repository = repository
    end

    def run_projection(projection_spec, stream_name)
      if projection_spec.instance_of?(Hash)
        run(Projection.new(projection_spec), stream_name)
      else
        run(projection_spec, stream_name)
      end
    end

    private
    def run(projection, stream_name)
      read_events_of_type(stream_name, projection.handled_events).
        reduce(projection.initial_state) { |state, event| projection.transition(state, event); state }
    end

    def read_events_of_type(stream_name, event_types)
      repository.
        read_stream_events_forward(stream_name).
        select { |event| event_types.any? { |type| event.instance_of?(type) } }
    end
  end
end
