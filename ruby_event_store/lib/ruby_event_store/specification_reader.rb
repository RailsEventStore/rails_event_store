# frozen_string_literal: true

module RubyEventStore
  # Used for fetching events based on given query specification.
  class SpecificationReader
    # @api private
    # @private
    def initialize(repository, mapper)
      @repository = repository
      @mapper = mapper
    end

    # @api private
    # @private
    def one(specification_result)
      record = repository.read(specification_result)
      mapper.record_to_event(record) if record
    end

    # @api private
    # @private
    def each(specification_result)
      repository.read(specification_result).each do |batch|
        yield batch.map { |record| mapper.record_to_event(record) }
      end
    end

    # @api private
    # @private
    def count(specification_result)
      repository.count(specification_result)
    end

    # @api private
    # @private
    def has_event?(event_id)
      repository.has_event?(event_id)
    end

    private
    attr_reader :repository, :mapper
  end
end
