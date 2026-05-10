class NullifyActivityEquipmentActionsOnEntryDelete < ActiveRecord::Migration[8.0]
  def up
    remove_foreign_key :activity_equipment_actions, :equipment_entries
    add_foreign_key :activity_equipment_actions, :equipment_entries, on_delete: :nullify
  end

  def down
    remove_foreign_key :activity_equipment_actions, :equipment_entries
    add_foreign_key :activity_equipment_actions, :equipment_entries
  end
end
