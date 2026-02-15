export interface TeamUser {
  id: number;
  assignment_id: number;
  full_name: string;
  initials: string;
  role_label: string;
  remove_path: string | null;
}

export interface TeamGroup {
  organization_name: string;
  users: TeamUser[];
}

export interface AssignedSummary {
  count: number;
  avatars: { id: number; initials: string; full_name: string }[];
  overflow: number;
}

export interface AssignableUser {
  id: number;
  full_name: string;
  role_label: string;
}

export interface Contact {
  id: number;
  name: string;
  title: string | null;
  email: string | null;
  phone: string | null;
  remove_path: string | null;
}

export interface Transition {
  value: string;
  label: string;
}

export interface IncidentDetail {
  id: number;
  path: string;
  transition_path: string;
  show_stats: boolean;
  stats: {
    total_labor_hours: number;
    active_equipment: number;
    total_equipment_placed: number;
    show_removed_equipment: boolean;
  };
  assignments_path: string;
  contacts_path: string;
  messages_path: string;
  description: string;
  cause: string | null;
  requested_next_steps: string | null;
  units_affected: number | null;
  affected_room_numbers: string | null;
  status: string;
  status_label: string;
  project_type: string;
  project_type_label: string;
  damage_type: string;
  damage_label: string;
  emergency: boolean;
  created_at: string;
  created_at_label: string;
  created_by: string | null;
  property: {
    id: number;
    name: string;
    address: string | null;
    path: string;
  };
  assigned_team: TeamGroup[];
  assigned_summary: AssignedSummary;
  contacts: Contact[];
  valid_transitions: Transition[];
}

export interface MessageAttachment {
  id: number;
  filename: string;
  category_label: string;
  url: string;
}

export interface Message {
  id: number;
  body: string;
  timestamp_label: string;
  date_label: string;
  show_date_separator: boolean;
  grouped: boolean;
  is_current_user: boolean;
  sender: {
    full_name: string;
    initials: string;
    role_label: string;
    org_name: string;
  };
  attachments?: MessageAttachment[];
}

export interface ShowProps {
  incident: IncidentDetail;
  messages: Message[];
  can_transition: boolean;
  can_assign: boolean;
  can_manage_contacts: boolean;
  assignable_users: AssignableUser[];
  back_path: string;
}
