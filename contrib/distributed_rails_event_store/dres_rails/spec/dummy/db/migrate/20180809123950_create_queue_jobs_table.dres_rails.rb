# This migration comes from dres_rails (originally 20180809123523)
class CreateQueueJobsTable < ActiveRecord::Migration[5.2]

  def change
    create_table :dres_rails_queue_jobs do |t|
      t.integer :queue_id, null: false
      t.string  :event_id, null: false
      t.string  :state,    null: false
    end
    add_index :dres_rails_queue_jobs, [:queue_id, :event_id]
  end

end