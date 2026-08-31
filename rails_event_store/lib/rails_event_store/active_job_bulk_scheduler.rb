# frozen_string_literal: true

require "active_job"

module RailsEventStore
  class ActiveJobBulkScheduler < ActiveJobScheduler
    include BulkEnqueue
  end
end
