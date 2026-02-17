import { useState } from "react";
import { router, usePage } from "@inertiajs/react";
import { X } from "lucide-react";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { SharedProps } from "@/types";
import type { AttachableEquipmentEntry, DailyActivity, EquipmentType } from "../types";

interface ActivityFormProps {
  path: string;
  equipment_types: EquipmentType[];
  attachable_equipment_entries: AttachableEquipmentEntry[];
  onClose: () => void;
  entry?: DailyActivity;
}

export default function ActivityForm({
  path,
  onClose,
  entry,
}: ActivityFormProps) {
  const editing = !!entry;
  const { now_datetime } = usePage<SharedProps>().props;
  const [title, setTitle] = useState(entry?.title ?? "");
  const [status, setStatus] = useState(entry?.status ?? "Active");
  const [occurredAt, setOccurredAt] = useState(entry?.occurred_at_value ?? now_datetime);
  const [unitsAffected, setUnitsAffected] = useState(entry?.units_affected ? String(entry.units_affected) : "");
  const [unitsAffectedDescription, setUnitsAffectedDescription] = useState(entry?.units_affected_description ?? "");
  const [details, setDetails] = useState(entry?.details ?? "");
  const [visitors, setVisitors] = useState(entry?.visitors ?? "");
  const [usableRoomsReturned, setUsableRoomsReturned] = useState(entry?.usable_rooms_returned ?? "");
  const [estimatedDateOfReturn, setEstimatedDateOfReturn] = useState(entry?.estimated_date_of_return ?? "");
  const [submitting, setSubmitting] = useState(false);

  const payload = {
    activity_entry: {
      title,
      status,
      occurred_at: occurredAt,
      units_affected: unitsAffected || null,
      units_affected_description: unitsAffectedDescription || null,
      details: details || null,
      visitors: visitors || null,
      usable_rooms_returned: usableRoomsReturned || null,
      estimated_date_of_return: estimatedDateOfReturn || null,
    },
  };

  const handleSubmit = (e: React.FormEvent) => {
    e.preventDefault();
    if (!title.trim() || !occurredAt || submitting) return;

    setSubmitting(true);
    const destination = editing ? entry!.edit_path! : path;
    const options = {
      preserveScroll: true,
      onSuccess: () => onClose(),
      onFinish: () => setSubmitting(false),
    };

    if (editing) {
      router.patch(destination, payload, options);
    } else {
      router.post(destination, payload, options);
    }
  };

  return (
    <div className="fixed inset-0 z-50 flex items-end sm:items-center justify-center">
      <div className="fixed inset-0 bg-black opacity-40" onClick={onClose} />
      <div className="relative bg-background border border-border rounded-t sm:rounded w-full sm:max-w-2xl p-4 shadow-lg max-h-[95vh] overflow-y-auto">
        <div className="flex items-center justify-between mb-4">
          <h3 className="text-sm font-semibold">{editing ? "Edit Activity" : "Add Activity"}</h3>
          <Button variant="ghost" size="sm" className="h-7 w-7 p-0" onClick={onClose}>
            <X className="h-4 w-4" />
          </Button>
        </div>

        <form onSubmit={handleSubmit} className="space-y-4">
          <div className="grid grid-cols-1 sm:grid-cols-3 gap-3">
            <div className="sm:col-span-2">
              <label className="text-xs font-medium text-muted-foreground">
                Activity <span className="text-destructive">*</span>
              </label>
              <Input
                value={title}
                onChange={(e) => setTitle(e.target.value)}
                className="mt-1"
                placeholder="e.g. Extract water"
                required
              />
            </div>
            <div>
              <label className="text-xs font-medium text-muted-foreground">Workflow Status</label>
              <Input
                value={status}
                onChange={(e) => setStatus(e.target.value)}
                className="mt-1"
                placeholder="e.g. Active, On Hold - Waiting for reports"
              />
            </div>
          </div>

          <div className="grid grid-cols-1 sm:grid-cols-2 gap-3">
            <div>
              <label className="text-xs font-medium text-muted-foreground">
                Occurred At <span className="text-destructive">*</span>
              </label>
              <Input
                type="datetime-local"
                value={occurredAt}
                onChange={(e) => setOccurredAt(e.target.value)}
                className="mt-1"
                required
              />
            </div>
            <div>
              <label className="text-xs font-medium text-muted-foreground">
                Units Affected <span className="text-muted-foreground font-normal">(optional)</span>
              </label>
              <Input
                type="number"
                min="1"
                value={unitsAffected}
                onChange={(e) => setUnitsAffected(e.target.value)}
                className="mt-1"
                placeholder="e.g. 2"
              />
            </div>
          </div>

          <div>
            <label className="text-xs font-medium text-muted-foreground">
              Units Affected Description <span className="text-muted-foreground font-normal">(optional)</span>
            </label>
            <Input
              value={unitsAffectedDescription}
              onChange={(e) => setUnitsAffectedDescription(e.target.value)}
              className="mt-1"
              placeholder="e.g. Units 237 and 239"
            />
          </div>

          <div>
            <label className="text-xs font-medium text-muted-foreground">
              Details / Reasoning <span className="text-muted-foreground font-normal">(optional)</span>
            </label>
            <textarea
              value={details}
              onChange={(e) => setDetails(e.target.value)}
              rows={2}
              className="mt-1 w-full rounded border border-input bg-background px-3 py-2 text-sm resize-none"
              placeholder="Why this was done and what changed"
            />
          </div>

          <div>
            <label className="text-xs font-medium text-muted-foreground">
              Visitors <span className="text-muted-foreground font-normal">(optional)</span>
            </label>
            <textarea
              value={visitors}
              onChange={(e) => setVisitors(e.target.value)}
              rows={2}
              className="mt-1 w-full rounded border border-input bg-background px-3 py-2 text-sm resize-none"
              placeholder="People present on-site..."
            />
          </div>

          <div className="grid grid-cols-1 sm:grid-cols-2 gap-3">
            <div>
              <label className="text-xs font-medium text-muted-foreground">
                Usable Rooms Returned <span className="text-muted-foreground font-normal">(optional)</span>
              </label>
              <Input
                value={usableRoomsReturned}
                onChange={(e) => setUsableRoomsReturned(e.target.value)}
                className="mt-1"
              />
            </div>
            <div>
              <label className="text-xs font-medium text-muted-foreground">
                Est. Date of Return <span className="text-muted-foreground font-normal">(optional)</span>
              </label>
              <Input
                type="date"
                value={estimatedDateOfReturn}
                onChange={(e) => setEstimatedDateOfReturn(e.target.value)}
                className="mt-1"
              />
            </div>
          </div>

          <div className="flex justify-end gap-2 pt-1">
            <Button type="button" variant="ghost" size="sm" onClick={onClose}>
              Cancel
            </Button>
            <Button type="submit" size="sm" disabled={submitting || !title.trim()}>
              {submitting ? "Saving..." : editing ? "Update Activity" : "Add Activity"}
            </Button>
          </div>
        </form>
      </div>
    </div>
  );
}
