class CreateIncidentReadStates < ActiveRecord::Migration[8.0]
  def change
    create_table :incident_read_states do |t|
      t.references :incident, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true
      t.datetime :last_message_read_at
      t.datetime :last_activity_read_at

      t.timestamps
    end

    add_index :incident_read_states, %i[incident_id user_id], unique: true
  end
end
