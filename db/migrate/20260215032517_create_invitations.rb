class CreateInvitations < ActiveRecord::Migration[8.0]
  def change
    create_table :invitations do |t|
      t.references :organization, null: false, foreign_key: true
      t.references :invited_by_user, null: false, foreign_key: { to_table: :users }
      t.string :email, null: false
      t.string :user_type, null: false
      t.string :first_name
      t.string :last_name
      t.string :phone
      t.string :token, null: false
      t.datetime :accepted_at
      t.datetime :expires_at, null: false

      t.timestamps
    end

    add_index :invitations, :token, unique: true
    add_index :invitations, :email
  end
end
