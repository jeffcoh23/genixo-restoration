class RenameModelNameToEquipmentModelInEquipmentItems < ActiveRecord::Migration[8.0]
  def change
    rename_column :equipment_items, :model_name, :equipment_model
  end
end
