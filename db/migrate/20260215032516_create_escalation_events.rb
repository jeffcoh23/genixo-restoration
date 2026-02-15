class CreateEscalationEvents < ActiveRecord::Migration[8.0]
  def change
    create_table :escalation_events do |t|
      t.references :incident, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true
      t.string :contact_method, null: false
      t.string :provider
      t.string :status, null: false
      t.datetime :attempted_at, null: false
      t.datetime :resolved_at
      t.references :resolved_by_user, foreign_key: { to_table: :users }
      t.string :resolution_reason
      t.jsonb :provider_response, default: {}

      t.datetime :created_at, null: false
    end

    add_index :escalation_events, :status
  end
end
