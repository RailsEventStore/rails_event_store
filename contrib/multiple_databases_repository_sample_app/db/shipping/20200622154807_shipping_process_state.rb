class ShippingProcessState < ActiveRecord::Migration[6.0]
  def change
    create_table :shipping_process_state, id: :string, primary_key: :order_id do |t|
      t.integer :customer_id
      t.integer :delivery_address_id
      t.binary :states
    end
  end
end
