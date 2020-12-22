require 'rom/sql'

::ROM::SQL.migration do
  change do
    alter_table(:event_store_events) do
      add_index :event_type
    end
  end
end
