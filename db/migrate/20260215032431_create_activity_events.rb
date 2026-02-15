class CreateActivityEvents < ActiveRecord::Migration[8.0]
  def change
    create_table :activity_events do |t|
      t.references :incident, null: false, foreign_key: true
      t.string :event_type, null: false
      t.references :performed_by_user, null: false, foreign_key: { to_table: :users }
      t.jsonb :metadata, null: false, default: {}

      t.datetime :created_at, null: false
    end

    add_index :activity_events, %i[incident_id created_at]
    add_index :activity_events, :event_type
  end
end
