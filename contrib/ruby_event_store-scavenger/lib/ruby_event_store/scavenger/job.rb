# frozen_string_literal: true

require "active_job"
require "ruby_event_store/scavenger"

module RubyEventStore
  module Scavenger
    # A scavenger run as a job, for setups without cron. A dry run unless execute: true.
    #
    #   RubyEventStore::Scavenger::Job.perform_later(execute: true, serializer: "json")
    #
    # The worker that performs it needs RES_SCAVENGER in its environment: run it in a worker
    # process of its own, on a queue no other worker takes.
    class Job < ::ActiveJob::Base
      # Options as of Runner, plus serializer ("yaml" or "json") and execute.
      def perform(execute: false, serializer: "yaml", **options)
        serializer = CLI::SERIALIZERS.fetch(serializer)
        Runner.active_record(serializer: serializer, **options).call(dry_run: !execute)
      end
    end
  end
end
