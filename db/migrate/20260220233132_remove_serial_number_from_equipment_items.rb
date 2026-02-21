class RemoveSerialNumberFromEquipmentItems < ActiveRecord::Migration[8.0]
  def change
    remove_column :equipment_items, :serial_number, :string
  end
end
