# frozen_string_literal: true

require "activerecord-import"

module RailsEventStoreActiveRecord
  class PgLinearizedEventRepository < EventRepository

    def start_transaction(requires_new, &proc)
      ActiveRecord::Base.transaction(requires_new: requires_new) do
        ActiveRecord::Base
          .connection
          .execute("SELECT pg_advisory_xact_lock(1845240511599988039) as l")
          .each{}

        proc.call
      end
    end

  end
end
