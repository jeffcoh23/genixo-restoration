class CreateEquipmentItems < ActiveRecord::Migration[8.0]
  def change
    create_table :equipment_items do |t|
      t.references :equipment_type, null: false, foreign_key: true
      t.references :organization, null: false, foreign_key: true
      t.string :model_name
      t.string :serial_number
      t.string :identifier, null: false
      t.boolean :active, default: true, null: false
      t.timestamps
    end

    add_index :equipment_items, [:organization_id, :identifier], unique: true

    add_reference :equipment_entries, :equipment_item, foreign_key: true
  end
end
