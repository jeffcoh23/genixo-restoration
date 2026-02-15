class CreateOperationalNotes < ActiveRecord::Migration[8.0]
  def change
    create_table :operational_notes do |t|
      t.references :incident, null: false, foreign_key: true
      t.references :created_by_user, null: false, foreign_key: { to_table: :users }
      t.text :note_text, null: false
      t.date :log_date, null: false

      t.datetime :created_at, null: false
    end

    add_index :operational_notes, %i[incident_id log_date]
    add_index :operational_notes, %i[incident_id created_at]
  end
end
