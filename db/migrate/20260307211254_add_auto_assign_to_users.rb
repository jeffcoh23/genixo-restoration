class AddAutoAssignToUsers < ActiveRecord::Migration[8.0]
  def change
    add_column :users, :auto_assign, :boolean, default: false, null: false
  end
end
