# frozen_string_literal: true

module RubyEventStore
  # @private
  class OneByOneMapping
    # @api private
    # @private
    def initialize(mapper)
      @mapper = mapper
    end

    # @api private
    # @private
    def call(batch)
      batch.map { |record| @mapper.record_to_event(record) }
    end
  end

  # @private
  class BatchMapping
    # @api private
    # @private
    def initialize(mapper)
      @mapper = mapper
    end

    # @api private
    # @private
    def call(batch)
      @mapper.records_to_events(batch)
    end
  end

  # Used for fetching events based on given query specification.
  class SpecificationReader
    # @api private
    # @private
    def initialize(repository, mapper, mapping: OneByOneMapping)
      @repository = repository
      @mapping = mapping.new(mapper)
    end

    # @api private
    # @private
    def one(specification_result)
      record = repository.read(specification_result)
      mapping.call([record]).first if record
    end

    # @api private
    # @private
    def each(specification_result)
      repository
        .read(specification_result)
        .each { |batch| yield mapping.call(batch) }
    end

    # @api private
    # @private
    def count(specification_result)
      repository.count(specification_result)
    end

    private

    attr_reader :repository, :mapping
  end
end
