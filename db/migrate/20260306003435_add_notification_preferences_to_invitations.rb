class AddNotificationPreferencesToInvitations < ActiveRecord::Migration[8.0]
  def change
    add_column :invitations, :notification_preferences, :jsonb, default: {}, null: false
  end
end
