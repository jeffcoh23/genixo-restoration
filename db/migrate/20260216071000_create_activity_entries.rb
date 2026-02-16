class CreateActivityEntries < ActiveRecord::Migration[8.0]
  def change
    create_table :activity_entries do |t|
      t.references :incident, null: false, foreign_key: true
      t.references :performed_by_user, null: false, foreign_key: { to_table: :users }
      t.string :title, null: false
      t.text :details
      t.integer :units_affected
      t.text :units_affected_description
      t.string :status, null: false, default: "active"
      t.datetime :occurred_at, null: false
      t.timestamps
    end

    add_index :activity_entries, [ :incident_id, :occurred_at ]
    add_index :activity_entries, :status
  end
end
