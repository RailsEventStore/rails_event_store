module DresRails
  class Queue < ActiveRecord::Base
    has_many :jobs, -> { order(:id) }

    def self.last_processed_event_id_for(app_name)
      where(name: app_name).pluck(:last_processed_event_id).first
    end

    def process(event_id, &job)
      error = nil
      with_lock do
        return if already_processed?(event_id)
        begin
          transaction(requires_new: true) do
            job.call
            jobs.create!(
              event_id: event_id,
              state: "success",
            )
          end
        rescue => x
          jobs.create!(
            event_id: event_id,
            state: "failure",
          )
          error = x
        ensure
          update_attributes!(last_processed_event_id: event_id)
        end
      end
      raise error if error
    end

    private

    def already_processed?(event_id)
      jobs.where(event_id: event_id, state: "success").exists?
    end

  end
end