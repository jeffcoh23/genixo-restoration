class AddTagNumberToEquipmentItems < ActiveRecord::Migration[8.0]
  def change
    add_column :equipment_items, :tag_number, :string
  end
end
