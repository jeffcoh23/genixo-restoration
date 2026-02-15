class CreatePropertyAssignments < ActiveRecord::Migration[8.0]
  def change
    create_table :property_assignments do |t|
      t.references :user, null: false, foreign_key: true
      t.references :property, null: false, foreign_key: true

      t.timestamps
    end

    add_index :property_assignments, %i[user_id property_id], unique: true
  end
end
