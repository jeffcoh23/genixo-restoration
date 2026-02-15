class CreateLaborEntries < ActiveRecord::Migration[8.0]
  def change
    create_table :labor_entries do |t|
      t.references :incident, null: false, foreign_key: true
      t.references :user, foreign_key: true
      t.string :role_label, null: false
      t.date :log_date, null: false
      t.datetime :started_at
      t.datetime :ended_at
      t.decimal :hours, precision: 5, scale: 2, null: false
      t.text :notes
      t.references :created_by_user, null: false, foreign_key: { to_table: :users }

      t.timestamps
    end

    add_index :labor_entries, %i[incident_id log_date]
  end
end
