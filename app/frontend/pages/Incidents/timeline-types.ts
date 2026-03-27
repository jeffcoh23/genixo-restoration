export interface TimelineTask {
  id: number;
  activity: string;
  start_date: string;
  end_date: string;
  position: number;
  update_path: string | null;
  destroy_path: string | null;
}

export interface TimelineUnit {
  id: number;
  unit_number: string;
  needs_vacant: boolean;
  position: number;
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
