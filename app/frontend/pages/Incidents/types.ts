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
  onsite: boolean;
  update_path: string | null;
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
  created_at: string;
  occurred_at: string;
  time_label: string | null;
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
  removed_at?: string | null;
}

export interface EquipmentLogEntry {
  id: string;
  equipment_entry_id: number | null;
  action: "add" | "remove" | "move" | "other";
  action_label: string;
  occurred_at: string;
  occurred_at_label: string;
  date_key: string;
  date_label: string;
  type_name: string;
  equipment_identifier: string | null;
  location_notes: string | null;
  reason: string | null;
  action_notes: string | null;
  actor_name: string;
  edit_path: string | null;
  remove_path: string | null;
  active: boolean;
}

export interface DailyActivityEquipmentAction {
  id: number;
  action_type: "add" | "remove" | "move" | "other";
  action_label: string;
  quantity: number | null;
  type_name: string | null;
  note: string | null;
  equipment_type_id: number | null;
  equipment_type_other: string | null;
  equipment_entry_id: number | null;
}

export interface DailyActivity {
  id: number;
  title: string;
  details: string | null;
  status: string;
  occurred_at: string;
  occurred_at_value: string;
  occurred_at_label: string;
  date_key: string;
  date_label: string;
  units_affected: number | null;
  units_affected_description: string | null;
  visitors: string | null;
  usable_rooms_returned: string | null;
  estimated_date_of_return: string | null;
  created_by_name: string;
  edit_path: string | null;
  equipment_actions: DailyActivityEquipmentAction[];
}

export interface OperationalNote {
  id: number;
  note_text: string;
  log_date: string;
  log_date_label: string;
  created_at: string;
  time_label: string | null;
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
  created_at: string;
  time_label: string | null;
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

export interface AttachableEquipmentEntry {
  id: number;
  label: string;
}

export interface DailyLogDate {
  key: string;
  label: string;
}

export interface DailyLogTableRow {
  id: string;
  occurred_at: string;
  time_label: string;
  row_type: "activity" | "labor" | "note" | "document";
  row_type_label: string;
  primary_label: string;
  status_label: string;
  units_label: string;
  detail_label: string;
  actor_name: string;
  edit_path: string | null;
  url?: string;
  visitors?: string | null;
  usable_rooms_returned?: string | null;
  estimated_date_of_return?: string | null;
}

export interface DailyLogTableGroup {
  date_key: string;
  date_label: string;
  rows: DailyLogTableRow[];
}

export interface IncidentDetail {
  id: number;
  path: string;
  edit_path: string | null;
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
  activity_entries_path: string;
  labor_entries_path: string;
  equipment_entries_path: string;
  operational_notes_path: string;
  attachments_path: string;
  description: string;
  cause: string | null;
  requested_next_steps: string | null;
  units_affected: number | null;
  affected_room_numbers: string | null;
  visitors: string | null;
  usable_rooms_returned: string | null;
  estimated_date_of_return: string | null;
  estimated_date_of_return_label: string | null;
  status: string;
  status_label: string;
  project_type: string;
  project_type_label: string;
  damage_type: string;
  damage_label: string;
  emergency: boolean;
  job_id: string | null;
  created_at: string;
  created_at_label: string;
  created_by: string | null;
  property: {
    id: number;
    name: string;
    address: string | null;
    path: string;
  };
  deployed_equipment: {
    id: string;
    type_name: string;
    quantity: number;
    last_event_label: string | null;
    last_event_at_label: string | null;
    note: string | null;
    actor_name: string | null;
  }[];
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

export interface ActivityEntry {
  id: string;
  occurred_at: string;
  timestamp_label: string;
  date_label: string;
  show_date_separator: boolean;
  actor_name: string;
  actor_initials: string;
  actor_role_label: string | null;
  actor_org_name: string | null;
  category: "message" | "status" | "assignment" | "labor" | "equipment" | "document" | "note" | "contact" | "system";
  title: string;
  detail: string | null;
}

export interface NewIncidentAssignableUser {
  id: number;
  full_name: string;
  role_label: string;
  organization_name: string;
  auto_assign: boolean;
}

export interface NewIncidentProps {
  properties: { id: number; name: string; address: string | null }[];
  project_types: { value: string; label: string }[];
  damage_types: { value: string; label: string }[];
  can_assign: boolean;
  can_manage_contacts: boolean;
  property_users: Record<string, NewIncidentAssignableUser[]>;
}

export interface EquipmentLogItem {
  id: number;
  type_name: string;
  equipment_identifier: string | null;
  location_notes: string | null;
  placed_at_label: string;
  removed_at_label: string | null;
  total_days: number;
  edit_path: string | null;
  remove_path: string | null;
  // Raw values for edit form (only present when editable)
  equipment_type_id?: number | null;
  equipment_type_other?: string | null;
  placed_at?: string;
  removed_at?: string | null;
}

export interface LaborLogEmployee {
  name: string;
  title: string;
  hours_by_date: Record<string, number>;
}

export interface LaborLog {
  dates: string[];
  date_labels: string[];
  employees: LaborLogEmployee[];
}

export interface ShowProps {
  incident: IncidentDetail;
  activity_entries: ActivityEntry[];
  daily_activities: DailyActivity[];
  daily_log_dates: DailyLogDate[];
  daily_log_table_groups: DailyLogTableGroup[];
  messages: Message[];
  labor_entries: LaborEntry[];
  operational_notes: OperationalNote[];
  attachments: IncidentAttachment[];
  equipment_log: EquipmentLogItem[];
  labor_log: LaborLog;
  can_transition: boolean;
  can_assign: boolean;
  can_manage_contacts: boolean;
  can_edit: boolean;
  can_manage_activities: boolean;
  can_manage_labor: boolean;
  can_manage_equipment: boolean;
  can_create_notes: boolean;
  project_types: { value: string; label: string }[];
  damage_types: { value: string; label: string }[];
  assignable_users: AssignableUser[];
  assignable_labor_users: AssignableUser[];
  equipment_types: EquipmentType[];
  attachable_equipment_entries: AttachableEquipmentEntry[];
  back_path: string;
}
