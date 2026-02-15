class CreateUsers < ActiveRecord::Migration[8.0]
  def change
    create_table :users do |t|
      t.references :organization, null: false, foreign_key: true
      t.string :email_address, null: false
      t.string :password_digest
      t.string :first_name, null: false
      t.string :last_name, null: false
      t.string :phone
      t.string :timezone, null: false, default: "America/New_York"
      t.string :user_type, null: false
      t.jsonb :notification_preferences, null: false, default: {}
      t.boolean :active, null: false, default: true

      t.timestamps
    end

    add_index :users, %i[organization_id email_address], unique: true
    add_index :users, :email_address
    add_index :users, %i[organization_id user_type]
  end
end
