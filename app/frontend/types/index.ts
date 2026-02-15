export interface AuthUser {
  id: number;
  email: string;
  first_name: string;
  last_name: string;
  full_name: string;
  initials: string;
  user_type: string;
  organization_type: string;
  organization_name: string;
  timezone: string;
}

export interface SharedProps {
  auth: {
    user: AuthUser | null;
    authenticated: boolean;
  };
  routes: {
    dashboard: string;
    incidents: string;
    new_incident: string;
    properties: string;
    new_property: string;
    organizations: string;
    new_organization: string;
    users: string;
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
