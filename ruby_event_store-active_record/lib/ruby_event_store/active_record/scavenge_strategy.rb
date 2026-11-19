# frozen_string_literal: true

module RubyEventStore
  module ActiveRecord
    # Scavenge strategy (see the "scavenge strategy" lint) for the tables of EventRepository
    # with the native truncation migrations in. It only runs SQL when the scavenger runner,
    # a separate gem, calls it.
    #
    # Hidden entries are rows of event_store_events_in_streams with truncated_at set. MARK
    # sets truncated_at on the rows up to a row id, SWEEP deletes rows marked before a cutoff.
    # A batch selects row ids first and then writes them with one statement that checks the
    # state again, so an entry marked or shown again in between is left alone. The ids are
    # selected apart because MySQL takes no LIMIT in a subquery of IN.
    class ScavengeStrategy
      def initialize(model_factory: WithDefaultModels.new)
        @model_factory = model_factory
      end

      def streams(after:, limit:)
        scope = metadata_klass.order(:stream).limit(limit)
        scope = scope.where(metadata_klass.arel_table[:stream].gt(after)) if after
        scope.pluck(:stream).map { |name| Stream.new(name) }
      end

      def plan(stream, now:, sweep_before:)
        boundaries = boundaries(stream, now)
        boundary = boundaries.values.max
        Scavenger::Plan.new(
          stream: stream,
          boundary: boundary,
          reasons: boundaries.keys,
          to_mark: count(markable(stream, boundary)),
          to_sweep: count(sweepable(stream, sweep_before)),
        )
      end

      def mark(plan, batch_size, now:)
        ids = markable(plan.stream, plan.boundary).order(id: :asc).limit(batch_size).pluck(:id)
        stream_klass.where(id: ids, truncated_at: nil).update_all(truncated_at: now)
      end

      def sweep(stream, batch_size, before:)
        ids = sweepable(stream, before).order(id: :asc).limit(batch_size).pluck(:id)
        stream_klass.where(id: ids).where(stream_table[:truncated_at].lt(before)).delete_all
      end

      private

      def boundaries(stream, now)
        truncated_upto_id, soft_deleted_at, max_count, max_age =
          metadata_klass.where(stream: stream.name).pick(:truncated_upto_id, :soft_deleted_at, :max_count, :max_age)
        {
          (soft_deleted_at ? :soft_delete : :truncate_before) => truncated_upto_id,
          :max_count => (visible(stream).order(id: :desc).offset(max_count).pick(:id) if max_count),
          :max_age => (visible(stream).where(stream_table[:created_at].lt(now - max_age)).maximum(:id) if max_age),
        }.compact
      end

      def visible(stream)
        stream_klass.where(stream: stream.name, truncated_at: nil)
      end

      def count(scope)
        scope.pick(stream_table[:id].count)
      end

      # Without a boundary "id <= NULL" matches nothing.
      def markable(stream, boundary)
        visible(stream).where(stream_table[:id].lteq(boundary))
      end

      def sweepable(stream, before)
        stream_klass
          .where(stream: stream.name)
          .where(stream_table[:truncated_at].lt(before))
          .where.not(event_id: stream_klass.where(stream: StreamMetadata.meta_stream(stream).name).select(:event_id))
          .where.not(id: anchor_id(stream))
      end

      # The entry that keeps the last stream version: the one with the highest position, the
      # newest one when entries have no position.
      def anchor_id(stream)
        entries = stream_klass.where(stream: stream.name)
        entries.where.not(position: nil).order(position: :desc).pick(:id) || entries.maximum(:id)
      end

      def stream_klass
        @stream_klass ||= @model_factory.call.last
      end

      def stream_table
        stream_klass.arel_table
      end

      # Any subclass with the table name set reads the same rows, so mutant's superclass mutation is equivalent.
      # mutant:disable
      def metadata_klass
        @metadata_klass ||= Class.new(stream_klass.superclass) { self.table_name = "event_store_streams_metadata" }
      end
    end
  end
end
