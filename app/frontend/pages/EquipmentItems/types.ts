export interface Placement {
  incident_id: number;
  property_name: string;
  job_id: string | null;
  placed_at: string;
  placed_at_formatted: string;
  removed_at: string | null;
  removed_at_formatted: string | null;
  location_notes: string | null;
}

export interface EquipmentItemRow {
  id: number;
  identifier: string;
  tag_number: string | null;
  equipment_make: string | null;
  equipment_model: string | null;
  type_name: string;
  equipment_type_id: number;
  active: boolean;
  edit_path: string;
  deployed: boolean;
  deployed_property: string | null;
  deployed_incident_id: number | null;
  placements: Placement[];
}

export interface EquipmentTypeOption {
  id: number;
  name: string;
}

export interface EquipmentTypeRow {
  id: number;
  name: string;
  active: boolean;
  deactivate_path: string | null;
  reactivate_path: string | null;
}

export type ItemForm = {
  equipment_type_id: string;
  identifier: string;
  tag_number: string;
  equipment_make: string;
  equipment_model: string;
};
