class AddNotificationOverridesToIncidentAssignments < ActiveRecord::Migration[8.0]
  def change
    add_column :incident_assignments, :notification_overrides, :jsonb, null: false, default: {}
  end
end
