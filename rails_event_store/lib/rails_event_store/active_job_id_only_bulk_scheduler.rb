# frozen_string_literal: true

require "active_job"

module RailsEventStore
  class ActiveJobIdOnlyBulkScheduler < ActiveJobIdOnlyScheduler
    include BulkEnqueue
  end
end
