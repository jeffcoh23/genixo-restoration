export interface TimelineTask {
  id: number;
  activity: string;
  start_date: string;
  end_date: string;
  start_date_label: string;
  end_date_label: string;
  position: number;
  update_path: string | null;
  destroy_path: string | null;
}

export interface TimelineUnit {
  id: number;
  unit_number: string;
  needs_vacant: boolean;
  position: number;
  min_start_date: string | null;
  update_path: string | null;
  destroy_path: string | null;
  create_task_path: string | null;
  tasks: TimelineTask[];
}

export interface TimelineIncident {
  id: number;
  path: string;
  description: string;
  status_label: string;
  display_status: string;
  property: {
    name: string;
    organization_name: string;
  };
}

export interface TimelineProps {
  incident: TimelineIncident;
  units: TimelineUnit[];
  can_manage: boolean;
  create_unit_path: string | null;
  back_path: string;
}

// SVAR Gantt requires JS Date objects. These helpers convert between
// server-provided ISO date strings and Date instances for the library API.
// This is data conversion for a third-party library, not display formatting.

export function parseISODate(iso: string): Date {
  const [y, m, d] = iso.split("-").map(Number);
  return new Date(y, m - 1, d);
}

export function dateToISO(date: Date): string {
  const y = date.getFullYear();
  const m = String(date.getMonth() + 1).padStart(2, "0");
  const d = String(date.getDate()).padStart(2, "0");
  return `${y}-${m}-${d}`;
}

export const GANTT_FALLBACK_DATE = new Date();
