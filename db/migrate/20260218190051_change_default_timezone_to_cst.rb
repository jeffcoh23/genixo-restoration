class ChangeDefaultTimezoneToCst < ActiveRecord::Migration[8.0]
  def change
    change_column_default :users, :timezone, from: "America/New_York", to: "America/Chicago"
  end
end
