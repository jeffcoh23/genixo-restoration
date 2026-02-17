import { useForm } from "@inertiajs/react";
import { X } from "lucide-react";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import type { IncidentDetail } from "../types";

interface IncidentEditFormProps {
  incident: IncidentDetail;
  project_types: { value: string; label: string }[];
  damage_types: { value: string; label: string }[];
  onClose: () => void;
}

export default function IncidentEditForm({ incident, project_types, damage_types, onClose }: IncidentEditFormProps) {
  const { data, setData, patch, processing, errors } = useForm({
    description: incident.description,
    cause: incident.cause ?? "",
    requested_next_steps: incident.requested_next_steps ?? "",
    units_affected: incident.units_affected != null ? String(incident.units_affected) : "",
    affected_room_numbers: incident.affected_room_numbers ?? "",
    job_id: incident.job_id ?? "",
    project_type: incident.project_type,
    damage_type: incident.damage_type,
  });

  const handleSubmit = (e: React.FormEvent) => {
    e.preventDefault();
    patch(incident.edit_path!, { onSuccess: () => onClose() });
  };

  return (
    <div className="fixed inset-0 z-50 flex items-start justify-center pt-16 sm:pt-24">
      <div className="fixed inset-0 bg-black opacity-40" onClick={onClose} />
      <div className="relative bg-background border border-border rounded w-full max-w-lg p-5 shadow-lg max-h-[80vh] overflow-y-auto">
        <div className="flex items-center justify-between mb-4">
          <h3 className="text-sm font-semibold">Edit Incident</h3>
          <Button variant="ghost" size="sm" className="h-7 w-7 p-0" onClick={onClose}>
            <X className="h-4 w-4" />
          </Button>
        </div>

        <form onSubmit={handleSubmit} className="space-y-4">
          {/* Project Type */}
          <div className="space-y-1.5">
            <Label htmlFor="edit_project_type" className="text-xs">Project Type</Label>
            <select
              id="edit_project_type"
              value={data.project_type}
              onChange={(e) => setData("project_type", e.target.value)}
              className="flex h-9 w-full rounded border border-input bg-muted px-3 py-1.5 text-sm ring-offset-background focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-ring focus-visible:ring-offset-2"
            >
              {project_types.map((pt) => (
                <option key={pt.value} value={pt.value}>{pt.label}</option>
              ))}
            </select>
            {errors.project_type && <p className="text-xs text-destructive">{errors.project_type}</p>}
          </div>

          {/* Damage Type */}
          <div className="space-y-1.5">
            <Label htmlFor="edit_damage_type" className="text-xs">Damage Type</Label>
            <select
              id="edit_damage_type"
              value={data.damage_type}
              onChange={(e) => setData("damage_type", e.target.value)}
              className="flex h-9 w-full rounded border border-input bg-muted px-3 py-1.5 text-sm ring-offset-background focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-ring focus-visible:ring-offset-2"
            >
              {damage_types.map((dt) => (
                <option key={dt.value} value={dt.value}>{dt.label}</option>
              ))}
            </select>
            {errors.damage_type && <p className="text-xs text-destructive">{errors.damage_type}</p>}
          </div>

          {/* Job ID */}
          <div className="space-y-1.5">
            <Label htmlFor="edit_job_id" className="text-xs">Job ID</Label>
            <Input
              id="edit_job_id"
              value={data.job_id}
              onChange={(e) => setData("job_id", e.target.value)}
              placeholder="Optional reference number"
              className="h-9"
            />
            {errors.job_id && <p className="text-xs text-destructive">{errors.job_id}</p>}
          </div>

          {/* Description */}
          <div className="space-y-1.5">
            <Label htmlFor="edit_description" className="text-xs">Description *</Label>
            <textarea
              id="edit_description"
              rows={4}
              value={data.description}
              onChange={(e) => setData("description", e.target.value)}
              className="flex w-full rounded border border-input bg-muted px-3 py-2 text-sm ring-offset-background placeholder:text-muted-foreground focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-ring focus-visible:ring-offset-2 resize-none"
            />
            {errors.description && <p className="text-xs text-destructive">{errors.description}</p>}
          </div>

          {/* Cause */}
          <div className="space-y-1.5">
            <Label htmlFor="edit_cause" className="text-xs">Cause</Label>
            <textarea
              id="edit_cause"
              rows={2}
              value={data.cause}
              onChange={(e) => setData("cause", e.target.value)}
              className="flex w-full rounded border border-input bg-muted px-3 py-2 text-sm ring-offset-background placeholder:text-muted-foreground focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-ring focus-visible:ring-offset-2 resize-none"
            />
            {errors.cause && <p className="text-xs text-destructive">{errors.cause}</p>}
          </div>

          {/* Requested Next Steps */}
          <div className="space-y-1.5">
            <Label htmlFor="edit_next_steps" className="text-xs">Requested Next Steps</Label>
            <textarea
              id="edit_next_steps"
              rows={2}
              value={data.requested_next_steps}
              onChange={(e) => setData("requested_next_steps", e.target.value)}
              className="flex w-full rounded border border-input bg-muted px-3 py-2 text-sm ring-offset-background placeholder:text-muted-foreground focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-ring focus-visible:ring-offset-2 resize-none"
            />
            {errors.requested_next_steps && <p className="text-xs text-destructive">{errors.requested_next_steps}</p>}
          </div>

          {/* Units + Room Numbers side by side */}
          <div className="grid grid-cols-2 gap-3">
            <div className="space-y-1.5">
              <Label htmlFor="edit_units" className="text-xs">Units Affected</Label>
              <Input
                id="edit_units"
                type="number"
                value={data.units_affected}
                onChange={(e) => setData("units_affected", e.target.value)}
                className="h-9"
              />
              {errors.units_affected && <p className="text-xs text-destructive">{errors.units_affected}</p>}
            </div>
            <div className="space-y-1.5">
              <Label htmlFor="edit_rooms" className="text-xs">Room Numbers</Label>
              <Input
                id="edit_rooms"
                value={data.affected_room_numbers}
                onChange={(e) => setData("affected_room_numbers", e.target.value)}
                placeholder="e.g. 101, 102, 205"
                className="h-9"
              />
              {errors.affected_room_numbers && <p className="text-xs text-destructive">{errors.affected_room_numbers}</p>}
            </div>
          </div>

          {/* Actions */}
          <div className="flex justify-end gap-2 pt-2">
            <Button type="button" variant="ghost" size="sm" onClick={onClose}>Cancel</Button>
            <Button type="submit" size="sm" disabled={processing}>
              {processing ? "Saving..." : "Save Changes"}
            </Button>
          </div>
        </form>
      </div>
    </div>
  );
}
