class CreateDresRailsQueues < ActiveRecord::Migration[5.2]
  def change
    create_table :dres_rails_queues do |t|
      t.string :name, null: false
      t.string :last_processed_event_id
      t.timestamps
    end
    add_index :dres_rails_queues, :name, unique: true
  end
end
