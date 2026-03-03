class CreatePsychrometricTables < ActiveRecord::Migration[8.0]
  def change
    create_table :psychrometric_points do |t|
      t.references :incident, null: false, foreign_key: true
      t.string :unit, null: false
      t.string :room, null: false
      t.string :dehumidifier_label
      t.integer :position
      t.timestamps
    end

    add_index :psychrometric_points, [:incident_id, :position]

    create_table :psychrometric_readings do |t|
      t.references :psychrometric_point, null: false, foreign_key: true
      t.date :log_date, null: false
      t.decimal :temperature, precision: 5, scale: 1
      t.decimal :relative_humidity, precision: 5, scale: 1
      t.decimal :gpp, precision: 7, scale: 1
      t.references :recorded_by_user, null: false, foreign_key: { to_table: :users }
      t.timestamps
    end

    add_index :psychrometric_readings, [:psychrometric_point_id, :log_date], unique: true, name: "idx_psychrometric_readings_point_date"
    add_index :psychrometric_readings, :log_date
  end
end
