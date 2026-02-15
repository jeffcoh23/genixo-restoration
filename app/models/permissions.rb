class Permissions
  # --- Permission constants ---
  CREATE_INCIDENT       = :create_incident
  TRANSITION_STATUS     = :transition_status
  CREATE_PROPERTY       = :create_property
  VIEW_PROPERTIES       = :view_properties
  MANAGE_ORGANIZATIONS  = :manage_organizations
  MANAGE_USERS          = :manage_users
  MANAGE_ON_CALL        = :manage_on_call
  MANAGE_EQUIPMENT_TYPES = :manage_equipment_types

  # --- Role → permissions map ---
  # Single source of truth. To grant a new permission to a role, add it here.
  # When we move to a database-backed system, this becomes the default fallback.
  ROLE_PERMISSIONS = {
    "manager" => [
      CREATE_INCIDENT, TRANSITION_STATUS, CREATE_PROPERTY, VIEW_PROPERTIES,
      MANAGE_ORGANIZATIONS, MANAGE_USERS, MANAGE_ON_CALL, MANAGE_EQUIPMENT_TYPES
    ],
    "office_sales" => [
      CREATE_INCIDENT, CREATE_PROPERTY, VIEW_PROPERTIES,
      MANAGE_ORGANIZATIONS, MANAGE_USERS
    ],
    "technician" => [],
    "property_manager" => [
      CREATE_INCIDENT, VIEW_PROPERTIES
    ],
    "area_manager" => [
      CREATE_INCIDENT, VIEW_PROPERTIES
    ],
    "pm_manager" => [
      VIEW_PROPERTIES
    ]
  }.freeze

  def self.has?(user_type, permission)
    ROLE_PERMISSIONS.fetch(user_type, []).include?(permission)
  end

  def self.for_role(user_type)
    ROLE_PERMISSIONS.fetch(user_type, [])
  end
end
