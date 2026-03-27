class CreateIncidentTasks < ActiveRecord::Migration[8.0]
  def change
    create_table :incident_tasks do |t|
      t.references :incident_unit, null: false, foreign_key: true
      t.string :activity, null: false
      t.date :start_date, null: false
      t.date :end_date, null: false
      t.integer :position, null: false, default: 0
      t.references :created_by_user, null: false, foreign_key: { to_table: :users }

      t.timestamps
    end

    add_index :incident_tasks, [:incident_unit_id, :position]
  end
end
