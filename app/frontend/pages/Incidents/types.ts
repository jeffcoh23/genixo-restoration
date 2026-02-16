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

export interface LaborEntry {
  id: number;
  role_label: string;
  hours: number;
  log_date: string;
  log_date_label: string;
  started_at_label: string | null;
  ended_at_label: string | null;
  notes: string | null;
  user_name: string | null;
  created_by_name: string;
  edit_path: string | null;
  // Raw values for edit form (only present when editable)
  started_at?: string | null;
  ended_at?: string | null;
  user_id?: number | null;
}

export interface EquipmentEntry {
  id: number;
  type_name: string;
  equipment_identifier: string | null;
  placed_at_label: string;
  removed_at_label: string | null;
  active: boolean;
  location_notes: string | null;
  logged_by_name: string;
  edit_path: string | null;
  remove_path: string | null;
  // Raw values for edit form (only present when editable)
  equipment_type_id?: number | null;
  equipment_type_other?: string | null;
  placed_at?: string;
}

export interface OperationalNote {
  id: number;
  note_text: string;
  log_date: string;
  log_date_label: string;
  created_at_label: string;
  created_by_name: string;
}

export interface IncidentAttachment {
  id: number;
  filename: string;
  category: string;
  category_label: string;
  description: string | null;
  log_date: string | null;
  log_date_label: string | null;
  created_at_label: string;
  uploaded_by_name: string;
  content_type: string;
  byte_size: number;
  url: string;
}

export interface EquipmentType {
  id: number;
  name: string;
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
  labor_entries_path: string;
  equipment_entries_path: string;
  operational_notes_path: string;
  attachments_path: string;
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
  labor_entries: LaborEntry[];
  equipment_entries: EquipmentEntry[];
  operational_notes: OperationalNote[];
  attachments: IncidentAttachment[];
  can_transition: boolean;
  can_assign: boolean;
  can_manage_contacts: boolean;
  can_manage_labor: boolean;
  can_manage_equipment: boolean;
  can_create_notes: boolean;
  assignable_users: AssignableUser[];
  assignable_labor_users: AssignableUser[];
  equipment_types: EquipmentType[];
  back_path: string;
}
