class AddEquipmentMakeAndTagColumns < ActiveRecord::Migration[8.0]
  def change
    add_column :equipment_items, :tag_number, :string
    add_column :equipment_items, :equipment_make, :string
    add_column :equipment_entries, :equipment_make, :string
    add_column :equipment_entries, :tag_number, :string
  end
end
