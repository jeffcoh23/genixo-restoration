class CreateIncidents < ActiveRecord::Migration[8.0]
  def change
    create_table :incidents do |t|
      t.references :property, null: false, foreign_key: true
      t.references :created_by_user, null: false, foreign_key: { to_table: :users }
      t.string :status, null: false, default: "new"
      t.string :project_type, null: false
      t.boolean :emergency, null: false, default: false
      t.string :damage_type, null: false
      t.text :description, null: false
      t.text :cause
      t.text :requested_next_steps
      t.integer :units_affected
      t.text :affected_room_numbers
      t.datetime :last_activity_at

      t.timestamps
    end

    add_index :incidents, %i[property_id status]
    add_index :incidents, :status
    add_index :incidents, %i[status last_activity_at]
    add_index :incidents, :last_activity_at
    add_index :incidents, :emergency, where: "emergency = true"
    add_index :incidents, :project_type
  end
end
