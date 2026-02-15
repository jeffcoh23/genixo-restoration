class CreateOnCallConfigurations < ActiveRecord::Migration[8.0]
  def change
    create_table :on_call_configurations do |t|
      t.references :organization, null: false, foreign_key: true, index: { unique: true }
      t.references :primary_user, null: false, foreign_key: { to_table: :users }
      t.integer :escalation_timeout_minutes, null: false, default: 10

      t.timestamps
    end
  end
end
