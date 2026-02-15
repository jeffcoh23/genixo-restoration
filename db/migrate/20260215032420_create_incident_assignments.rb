class CreateIncidentAssignments < ActiveRecord::Migration[8.0]
  def change
    create_table :incident_assignments do |t|
      t.references :incident, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true
      t.references :assigned_by_user, null: false, foreign_key: { to_table: :users }

      t.timestamps
    end

    add_index :incident_assignments, %i[incident_id user_id], unique: true
  end
end
