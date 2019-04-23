module DresRails
  class Job < ActiveRecord::Base
    self.table_name = "dres_rails_queue_jobs"
  end
end