class AddTitleToLoginRequests < ActiveRecord::Migration[8.0]
  def change
    add_column :login_requests, :title, :string
  end
end
