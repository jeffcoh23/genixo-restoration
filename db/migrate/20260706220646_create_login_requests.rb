class CreateLoginRequests < ActiveRecord::Migration[8.0]
  def change
    create_table :login_requests do |t|
      t.string :email, null: false
      t.string :first_name, null: false
      t.string :last_name, null: false
      t.string :company_name
      t.string :phone
      t.text :message
      t.string :status, null: false, default: "pending"
      t.references :reviewed_by_user, foreign_key: { to_table: :users }
      t.datetime :reviewed_at
      t.text :rejection_reason

      t.timestamps
    end

    add_index :login_requests, :status
    add_index :login_requests, :email
  end
end
