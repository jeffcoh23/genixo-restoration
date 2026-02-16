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
  CREATE_LABOR          = :create_labor
  CREATE_EQUIPMENT      = :create_equipment
  CREATE_OPERATIONAL_NOTE = :create_operational_note

  # --- Role → permissions map ---
  # Single source of truth. To grant a new permission to a role, add it here.
  # When we move to a database-backed system, this becomes the default fallback.
  ROLE_PERMISSIONS = {
    User::MANAGER => [
      CREATE_INCIDENT, TRANSITION_STATUS, CREATE_PROPERTY, VIEW_PROPERTIES,
      MANAGE_ORGANIZATIONS, MANAGE_USERS, MANAGE_ON_CALL, MANAGE_EQUIPMENT_TYPES,
      CREATE_LABOR, CREATE_EQUIPMENT, CREATE_OPERATIONAL_NOTE
    ],
    User::OFFICE_SALES => [
      CREATE_INCIDENT, CREATE_PROPERTY, VIEW_PROPERTIES,
      MANAGE_ORGANIZATIONS, MANAGE_USERS
    ],
    User::TECHNICIAN => [
      CREATE_LABOR, CREATE_EQUIPMENT, CREATE_OPERATIONAL_NOTE
    ],
    User::PROPERTY_MANAGER => [
      CREATE_INCIDENT, VIEW_PROPERTIES
    ],
    User::AREA_MANAGER => [
      CREATE_INCIDENT, VIEW_PROPERTIES
    ],
    User::PM_MANAGER => [
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
