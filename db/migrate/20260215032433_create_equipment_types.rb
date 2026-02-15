class CreateEquipmentTypes < ActiveRecord::Migration[8.0]
  def change
    create_table :equipment_types do |t|
      t.references :organization, null: false, foreign_key: true
      t.string :name, null: false
      t.boolean :active, null: false, default: true

      t.timestamps
    end

    add_index :equipment_types, %i[organization_id name], unique: true
  end
end
