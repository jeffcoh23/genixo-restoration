class AddPerUserPermissions < ActiveRecord::Migration[8.0]
  def up
    # Add title and permissions columns to users
    add_column :users, :title, :string
    add_column :users, :permissions, :jsonb, default: [], null: false

    # Add title and permissions columns to invitations
    add_column :invitations, :title, :string
    add_column :invitations, :permissions, :jsonb, default: [], null: false

    # Rename pm_manager → other in users
    User.where(user_type: "pm_manager").update_all(user_type: "other")

    # Rename pm_manager → other in invitations
    Invitation.where(user_type: "pm_manager").update_all(user_type: "other")

    # Backfill existing users' permissions from role defaults
    role_permissions = {
      "manager" => %w[create_incident edit_incident transition_status create_property view_properties manage_organizations manage_users manage_on_call manage_equipment_types create_labor create_equipment create_operational_note manage_moisture_readings manage_attachments manage_psychrometric_readings],
      "office_sales" => %w[create_incident edit_incident create_property view_properties manage_organizations manage_users manage_attachments],
      "technician" => %w[create_labor create_equipment create_operational_note manage_moisture_readings manage_attachments manage_psychrometric_readings],
      "property_manager" => %w[create_incident view_properties],
      "area_manager" => %w[create_incident view_properties],
      "other" => %w[view_properties]
    }

    role_permissions.each do |role, perms|
      User.where(user_type: role).update_all(permissions: perms)
    end
  end

  def down
    # Rename other → pm_manager in users and invitations
    User.where(user_type: "other").update_all(user_type: "pm_manager")
    Invitation.where(user_type: "other").update_all(user_type: "pm_manager")

    remove_column :users, :permissions
    remove_column :users, :title
    remove_column :invitations, :permissions
    remove_column :invitations, :title
  end
end
