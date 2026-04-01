class CreateIncidentUnits < ActiveRecord::Migration[8.0]
  def change
    create_table :incident_units do |t|
      t.references :incident, null: false, foreign_key: true
      t.string :unit_number, null: false
      t.boolean :needs_vacant, null: false, default: false
      t.integer :position, null: false, default: 0
      t.references :created_by_user, null: false, foreign_key: { to_table: :users }

      t.timestamps
    end

    add_index :incident_units, [ :incident_id, :position ]
  end
end
