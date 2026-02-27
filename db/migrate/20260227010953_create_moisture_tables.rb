class CreateMoistureTables < ActiveRecord::Migration[8.0]
  def change
    create_table :moisture_measurement_points do |t|
      t.references :incident, null: false, foreign_key: true
      t.string :unit, null: false
      t.string :room, null: false
      t.string :item, null: false
      t.string :material, null: false
      t.string :goal, null: false
      t.string :measurement_unit, null: false
      t.integer :position
      t.timestamps
    end

    add_index :moisture_measurement_points, [ :incident_id, :position ]

    create_table :moisture_readings do |t|
      t.references :moisture_measurement_point, null: false, foreign_key: true
      t.date :log_date, null: false
      t.decimal :value, precision: 6, scale: 1
      t.references :recorded_by_user, null: false, foreign_key: { to_table: :users }
      t.timestamps
    end

    add_index :moisture_readings, [ :moisture_measurement_point_id, :log_date ], unique: true, name: "idx_moisture_readings_point_date"
    add_index :moisture_readings, :log_date

    add_column :incidents, :moisture_supervisor_pm, :string
  end
end
