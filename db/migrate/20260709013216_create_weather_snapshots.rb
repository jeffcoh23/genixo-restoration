class CreateWeatherSnapshots < ActiveRecord::Migration[8.0]
  def change
    create_table :weather_snapshots do |t|
      t.references :incident, null: false, foreign_key: true
      t.date :date, null: false
      # Fahrenheit / mph / inches — Visual Crossing US unit group. Cached on
      # first fetch so DFR regeneration never re-hits the API or loses the line.
      t.decimal :temp_max, precision: 5, scale: 1
      t.decimal :temp_min, precision: 5, scale: 1
      t.decimal :temp_avg, precision: 5, scale: 1
      t.string :conditions
      t.decimal :precip, precision: 6, scale: 2
      t.integer :precip_probability
      t.decimal :wind_speed, precision: 5, scale: 1
      t.integer :humidity
      t.datetime :fetched_at, null: false

      t.timestamps
    end

    # One snapshot per incident+date; the weather for a past date is immutable,
    # so a unique index also backstops a double-generate race.
    add_index :weather_snapshots, [ :incident_id, :date ], unique: true
  end
end
