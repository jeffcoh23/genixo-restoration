class RemoveEquipmentTypeXorConstraint < ActiveRecord::Migration[8.0]
  def up
    remove_check_constraint :equipment_entries, name: "equipment_type_xor"
  end

  def down
    add_check_constraint :equipment_entries,
      "(equipment_type_id IS NOT NULL AND equipment_type_other IS NULL) OR (equipment_type_id IS NULL AND equipment_type_other IS NOT NULL)",
      name: "equipment_type_xor"
  end
end
