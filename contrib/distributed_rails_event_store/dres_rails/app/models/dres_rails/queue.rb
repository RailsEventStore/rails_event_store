module DresRails
  class Queue < ApplicationRecord

    def self.last_processed_event_id_for(app_name)
      where(name: app_name).pluck(:last_processed_event_id).first
    end

  end
end