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
  MANAGE_DAILY_LOGS     = :manage_daily_logs
  EDIT_INCIDENT         = :edit_incident
  MANAGE_READINGS       = :manage_readings
  MANAGE_ATTACHMENTS    = :manage_attachments
  MANAGE_TIMELINE       = :manage_timeline

  # --- Role → permissions map ---
  # Single source of truth. To grant a new permission to a role, add it here.
  # When we move to a database-backed system, this becomes the default fallback.
  ROLE_PERMISSIONS = {
    User::MANAGER => [
      CREATE_INCIDENT, EDIT_INCIDENT, TRANSITION_STATUS, CREATE_PROPERTY, VIEW_PROPERTIES,
      MANAGE_ORGANIZATIONS, MANAGE_USERS, MANAGE_ON_CALL, MANAGE_EQUIPMENT_TYPES,
      MANAGE_DAILY_LOGS, MANAGE_READINGS, MANAGE_ATTACHMENTS, MANAGE_TIMELINE
    ],
    User::OFFICE_SALES => [
      CREATE_INCIDENT, EDIT_INCIDENT, CREATE_PROPERTY, VIEW_PROPERTIES,
      MANAGE_ORGANIZATIONS, MANAGE_USERS, MANAGE_ATTACHMENTS
    ],
    User::TECHNICIAN => [
      MANAGE_DAILY_LOGS, MANAGE_READINGS, MANAGE_ATTACHMENTS, MANAGE_TIMELINE
    ],
    User::PROPERTY_MANAGER => [
      CREATE_INCIDENT, VIEW_PROPERTIES
    ],
    User::AREA_MANAGER => [
      CREATE_INCIDENT, VIEW_PROPERTIES
    ],
    User::OTHER => [
      VIEW_PROPERTIES
    ],
    User::GUEST => []
  }.freeze

  ALL_PERMISSIONS = [
    CREATE_INCIDENT, EDIT_INCIDENT, TRANSITION_STATUS,
    CREATE_PROPERTY, VIEW_PROPERTIES,
    MANAGE_ORGANIZATIONS, MANAGE_USERS, MANAGE_ON_CALL, MANAGE_EQUIPMENT_TYPES,
    MANAGE_DAILY_LOGS, MANAGE_READINGS, MANAGE_ATTACHMENTS, MANAGE_TIMELINE
  ].freeze

  # Permissions shown as toggleable checkboxes in the UI (mitigation users only)
  MITIGATION_VISIBLE_PERMISSIONS = [
    CREATE_INCIDENT, EDIT_INCIDENT, TRANSITION_STATUS,
    MANAGE_DAILY_LOGS, MANAGE_READINGS, MANAGE_USERS, MANAGE_TIMELINE
  ].freeze

  PERMISSION_LABELS = {
    CREATE_INCIDENT => "Create incidents",
    EDIT_INCIDENT => "Edit incidents",
    TRANSITION_STATUS => "Change incident status",
    CREATE_PROPERTY => "Create properties",
    VIEW_PROPERTIES => "View properties",
    MANAGE_ORGANIZATIONS => "Manage organizations",
    MANAGE_USERS => "Manage users",
    MANAGE_ON_CALL => "Manage on-call",
    MANAGE_EQUIPMENT_TYPES => "Manage equipment types",
    MANAGE_DAILY_LOGS => "Log daily work",
    MANAGE_READINGS => "Manage readings",
    MANAGE_ATTACHMENTS => "Manage attachments",
    MANAGE_TIMELINE => "Manage timeline"
  }.freeze

  def self.has?(user_type, permission)
    ROLE_PERMISSIONS.fetch(user_type, []).include?(permission)
  end

  def self.for_role(user_type)
    ROLE_PERMISSIONS.fetch(user_type, [])
  end

  def self.defaults_for(user_type)
    for_role(user_type).map(&:to_s)
  end
end
