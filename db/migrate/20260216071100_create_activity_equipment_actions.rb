class CreateActivityEquipmentActions < ActiveRecord::Migration[8.0]
  def change
    create_table :activity_equipment_actions do |t|
      t.references :activity_entry, null: false, foreign_key: true
      t.references :equipment_type, foreign_key: true
      t.references :equipment_entry, foreign_key: true
      t.string :equipment_type_other
      t.string :action_type, null: false
      t.integer :quantity
      t.text :note
      t.integer :position, null: false, default: 0
      t.timestamps
    end

    add_index :activity_equipment_actions, [ :activity_entry_id, :position ], name: "index_act_eq_actions_on_entry_and_position"
    add_index :activity_equipment_actions, :action_type
  end
end
