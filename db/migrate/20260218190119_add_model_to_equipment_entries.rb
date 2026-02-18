class AddModelToEquipmentEntries < ActiveRecord::Migration[8.0]
  def change
    add_column :equipment_entries, :equipment_model, :string
  end
end
