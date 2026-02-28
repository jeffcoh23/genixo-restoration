import { useForm } from "@inertiajs/react";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from "@/components/ui/select";
import { Textarea } from "@/components/ui/textarea";
import { Dialog, DialogContent, DialogHeader, DialogTitle } from "@/components/ui/dialog";
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
    do_not_exceed_limit: incident.do_not_exceed_limit ?? "",
    location_of_damage: incident.location_of_damage ?? "",
    project_type: incident.project_type,
    damage_type: incident.damage_type,
  });

  const handleSubmit = (e: React.FormEvent) => {
    e.preventDefault();
    patch(incident.edit_path!, { onSuccess: () => onClose() });
  };

  return (
    <Dialog open onOpenChange={(open) => !open && onClose()}>
      <DialogContent className="sm:max-w-lg lg:max-w-2xl max-h-[80vh] overflow-y-auto">
        <DialogHeader>
          <DialogTitle>Edit Incident</DialogTitle>
        </DialogHeader>

        <form onSubmit={handleSubmit} className="space-y-4">
          {/* Project Type */}
          <div className="space-y-1.5">
            <Label className="text-xs">Project Type</Label>
            <Select value={data.project_type} onValueChange={(v) => setData("project_type", v)}>
              <SelectTrigger className="h-9">
                <SelectValue />
              </SelectTrigger>
              <SelectContent>
                {project_types.map((pt) => (
                  <SelectItem key={pt.value} value={pt.value}>{pt.label}</SelectItem>
                ))}
              </SelectContent>
            </Select>
            {errors.project_type && <p className="text-xs text-destructive">{errors.project_type}</p>}
          </div>

          {/* Damage Type */}
          <div className="space-y-1.5">
            <Label className="text-xs">Damage Type</Label>
            <Select value={data.damage_type} onValueChange={(v) => setData("damage_type", v)}>
              <SelectTrigger className="h-9">
                <SelectValue />
              </SelectTrigger>
              <SelectContent>
                {damage_types.map((dt) => (
                  <SelectItem key={dt.value} value={dt.value}>{dt.label}</SelectItem>
                ))}
              </SelectContent>
            </Select>
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

          {/* Emergency limit */}
          <div className="space-y-1.5">
            <Label htmlFor="edit_do_not_exceed" className="text-xs">Emergency Do Not Exceed Limit</Label>
            <Input
              id="edit_do_not_exceed"
              inputMode="numeric"
              value={data.do_not_exceed_limit}
              onChange={(e) => setData("do_not_exceed_limit", e.target.value.replace(/[^0-9]/g, ""))}
              placeholder="Optional dollar amount"
              className="h-9"
            />
            {errors.do_not_exceed_limit && <p className="text-xs text-destructive">{errors.do_not_exceed_limit}</p>}
          </div>

          {/* Location */}
          <div className="space-y-1.5">
            <Label htmlFor="edit_location" className="text-xs">Location of Damage</Label>
            <Textarea
              id="edit_location"
              rows={2}
              value={data.location_of_damage}
              onChange={(e) => setData("location_of_damage", e.target.value)}
              className="resize-none"
            />
            {errors.location_of_damage && <p className="text-xs text-destructive">{errors.location_of_damage}</p>}
          </div>

          {/* Description */}
          <div className="space-y-1.5">
            <Label htmlFor="edit_description" className="text-xs">Description *</Label>
            <Textarea
              id="edit_description"
              rows={4}
              value={data.description}
              onChange={(e) => setData("description", e.target.value)}
              className="resize-none"
            />
            {errors.description && <p className="text-xs text-destructive">{errors.description}</p>}
          </div>

          {/* Cause */}
          <div className="space-y-1.5">
            <Label htmlFor="edit_cause" className="text-xs">Cause</Label>
            <Textarea
              id="edit_cause"
              rows={2}
              value={data.cause}
              onChange={(e) => setData("cause", e.target.value)}
              className="resize-none"
            />
            {errors.cause && <p className="text-xs text-destructive">{errors.cause}</p>}
          </div>

          {/* Requested Next Steps */}
          <div className="space-y-1.5">
            <Label htmlFor="edit_next_steps" className="text-xs">Requested Next Steps</Label>
            <Textarea
              id="edit_next_steps"
              rows={2}
              value={data.requested_next_steps}
              onChange={(e) => setData("requested_next_steps", e.target.value)}
              className="resize-none"
            />
            {errors.requested_next_steps && <p className="text-xs text-destructive">{errors.requested_next_steps}</p>}
          </div>

          {/* Units + Room Numbers side by side */}
          <div className="grid grid-cols-2 gap-3">
            <div className="space-y-1.5">
              <Label htmlFor="edit_units" className="text-xs">Units Affected</Label>
              <Input
                id="edit_units"
                inputMode="numeric"
                value={data.units_affected}
                onChange={(e) => setData("units_affected", e.target.value.replace(/[^0-9]/g, ""))}
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
      </DialogContent>
    </Dialog>
  );
}
