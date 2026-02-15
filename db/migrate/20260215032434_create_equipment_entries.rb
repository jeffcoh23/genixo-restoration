class CreateEquipmentEntries < ActiveRecord::Migration[8.0]
  def change
    create_table :equipment_entries do |t|
      t.references :incident, null: false, foreign_key: true
      t.references :equipment_type, foreign_key: true
      t.string :equipment_type_other
      t.string :equipment_identifier
      t.datetime :placed_at, null: false
      t.datetime :removed_at
      t.text :location_notes
      t.references :logged_by_user, null: false, foreign_key: { to_table: :users }

      t.timestamps
    end

    add_index :equipment_entries, :equipment_identifier
  end
end
