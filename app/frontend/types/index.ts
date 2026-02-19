export interface AuthUser {
  id: number;
  email: string;
  first_name: string;
  last_name: string;
  full_name: string;
  initials: string;
  user_type: string;
  role_label: string;
  organization_type: string;
  organization_name: string;
  timezone: string;
}

export interface NavItem {
  label: string;
  href: string;
  icon: string;
}

export interface Permissions {
  can_create_incident: boolean;
  can_transition_status: boolean;
  can_create_property: boolean;
  can_view_properties: boolean;
  can_manage_organizations: boolean;
  can_manage_users: boolean;
  can_create_labor: boolean;
  can_create_equipment: boolean;
  can_create_operational_note: boolean;
}

export interface SharedProps extends Record<string, unknown> {
  auth: {
    user: AuthUser | null;
    authenticated: boolean;
  };
  permissions: Permissions;
  has_unread_incidents: boolean;
  today: string;
  now_datetime: string;
  nav_items: NavItem[];
  routes: {
    dashboard: string;
    incidents: string;
    new_incident: string;
    properties: string;
    new_property: string;
    organizations: string;
    new_organization: string;
    users: string;
    invitations: string;
    settings: string;
    on_call: string;
    equipment_types: string;
    login: string;
    logout: string;
  };
  flash: {
    notice?: string;
    alert?: string;
  };
}
