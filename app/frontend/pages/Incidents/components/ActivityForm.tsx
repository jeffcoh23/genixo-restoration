import { useState } from "react";
import { router, usePage } from "@inertiajs/react";
import { X } from "lucide-react";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { SharedProps } from "@/types";
import type { AttachableEquipmentEntry, DailyActivity, EquipmentType } from "../types";

type EquipmentActionType = "add" | "remove" | "move" | "other";

interface EquipmentActionDraft {
  action_type: EquipmentActionType;
  quantity: string;
  equipment_type_id: string;
  equipment_type_other: string;
  equipment_entry_id: string;
  note: string;
}

interface ActivityFormProps {
  path: string;
  equipment_types: EquipmentType[];
  attachable_equipment_entries: AttachableEquipmentEntry[];
  onClose: () => void;
  entry?: DailyActivity;
}

function blankEquipmentAction(): EquipmentActionDraft {
  return {
    action_type: "add",
    quantity: "",
    equipment_type_id: "",
    equipment_type_other: "",
    equipment_entry_id: "",
    note: "",
  };
}

export default function ActivityForm({
  path,
  equipment_types,
  attachable_equipment_entries,
  onClose,
  entry,
}: ActivityFormProps) {
  const editing = !!entry;
  const { now_datetime } = usePage<SharedProps>().props;
  const [title, setTitle] = useState(entry?.title ?? "");
  const [status, setStatus] = useState<"active" | "completed">(entry?.status ?? "active");
  const [occurredAt, setOccurredAt] = useState(entry?.occurred_at_value ?? now_datetime);
  const [unitsAffected, setUnitsAffected] = useState(entry?.units_affected ? String(entry.units_affected) : "");
  const [unitsAffectedDescription, setUnitsAffectedDescription] = useState(entry?.units_affected_description ?? "");
  const [details, setDetails] = useState(entry?.details ?? "");
  const [equipmentActions, setEquipmentActions] = useState<EquipmentActionDraft[]>(
    entry?.equipment_actions.length
      ? entry.equipment_actions.map((action) => ({
        action_type: action.action_type,
        quantity: action.quantity ? String(action.quantity) : "",
        equipment_type_id: action.equipment_type_id ? String(action.equipment_type_id) : "",
        equipment_type_other: action.equipment_type_other ?? "",
        equipment_entry_id: action.equipment_entry_id ? String(action.equipment_entry_id) : "",
        note: action.note ?? "",
      }))
      : [ blankEquipmentAction() ],
  );
  const [submitting, setSubmitting] = useState(false);

  const updateAction = (index: number, updates: Partial<EquipmentActionDraft>) => {
    setEquipmentActions((prev) => prev.map((action, i) => (i === index ? { ...action, ...updates } : action)));
  };

  const removeAction = (index: number) => {
    setEquipmentActions((prev) => (prev.length <= 1 ? [ blankEquipmentAction() ] : prev.filter((_, i) => i !== index)));
  };

  const addAction = () => setEquipmentActions((prev) => [ ...prev, blankEquipmentAction() ]);

  const payload = {
    activity_entry: {
      title,
      status,
      occurred_at: occurredAt,
      units_affected: unitsAffected || null,
      units_affected_description: unitsAffectedDescription || null,
      details: details || null,
      equipment_actions: equipmentActions.map((action, index) => ({
        action_type: action.action_type,
        quantity: action.quantity || null,
        equipment_type_id: action.equipment_type_id || null,
        equipment_type_other: action.equipment_type_other || null,
        equipment_entry_id: action.equipment_entry_id || null,
        note: action.note || null,
        position: index,
      })),
    },
  };

  const handleSubmit = (e: React.FormEvent) => {
    e.preventDefault();
    if (!title.trim() || !occurredAt || submitting) return;

    setSubmitting(true);
    const request = editing ? router.patch : router.post;
    const destination = editing ? entry!.edit_path! : path;

    request(destination, payload, {
      preserveScroll: true,
      onSuccess: () => onClose(),
      onFinish: () => setSubmitting(false),
    });
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
              <label className="text-xs font-medium text-muted-foreground">Activity</label>
              <Input
                value={title}
                onChange={(e) => setTitle(e.target.value)}
                className="mt-1"
                placeholder="e.g. Extract water"
                required
              />
            </div>
            <div>
              <label className="text-xs font-medium text-muted-foreground">Status</label>
              <select
                value={status}
                onChange={(e) => setStatus(e.target.value as "active" | "completed")}
                className="mt-1 w-full rounded border border-input bg-background px-3 py-2 text-sm"
              >
                <option value="active">Active</option>
                <option value="completed">Completed</option>
              </select>
            </div>
          </div>

          <div className="grid grid-cols-1 sm:grid-cols-2 gap-3">
            <div>
              <label className="text-xs font-medium text-muted-foreground">Occurred At</label>
              <Input
                type="datetime-local"
                value={occurredAt}
                onChange={(e) => setOccurredAt(e.target.value)}
                className="mt-1"
                required
              />
            </div>
            <div>
              <label className="text-xs font-medium text-muted-foreground">Units Affected (optional)</label>
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
            <label className="text-xs font-medium text-muted-foreground">Units Affected Description (optional)</label>
            <Input
              value={unitsAffectedDescription}
              onChange={(e) => setUnitsAffectedDescription(e.target.value)}
              className="mt-1"
              placeholder="e.g. Units 237 and 239"
            />
          </div>

          <div>
            <label className="text-xs font-medium text-muted-foreground">Details / Reasoning (optional)</label>
            <textarea
              value={details}
              onChange={(e) => setDetails(e.target.value)}
              rows={2}
              className="mt-1 w-full rounded border border-input bg-background px-3 py-2 text-sm resize-none"
              placeholder="Why this was done and what changed"
            />
          </div>

          <div className="rounded border border-border p-3">
            <div className="flex items-center justify-between mb-2">
              <p className="text-xs font-semibold uppercase tracking-wide text-muted-foreground">
                Equipment Actions (optional)
              </p>
              <Button type="button" variant="outline" size="sm" className="h-7 text-xs" onClick={addAction}>
                Add Action
              </Button>
            </div>

            <div className="space-y-2">
              {equipmentActions.map((action, index) => {
                const usingOtherType = action.equipment_type_id === "__other__";

                return (
                  <div key={`equipment-action-${index}`} className="rounded border border-border bg-muted p-2.5 space-y-2">
                    <div className="grid grid-cols-1 sm:grid-cols-4 gap-2">
                      <div>
                        <label className="text-xs font-medium text-muted-foreground">Action</label>
                        <select
                          value={action.action_type}
                          onChange={(e) => updateAction(index, { action_type: e.target.value as EquipmentActionType })}
                          className="mt-1 w-full rounded border border-input bg-background px-2 py-1.5 text-xs"
                        >
                          <option value="add">Add</option>
                          <option value="remove">Remove</option>
                          <option value="move">Move</option>
                          <option value="other">Other</option>
                        </select>
                      </div>

                      <div>
                        <label className="text-xs font-medium text-muted-foreground">Quantity</label>
                        <Input
                          type="number"
                          min="1"
                          value={action.quantity}
                          onChange={(e) => updateAction(index, { quantity: e.target.value })}
                          className="mt-1 h-8 text-xs"
                          placeholder="e.g. 4"
                        />
                      </div>

                      <div className="sm:col-span-2">
                        <label className="text-xs font-medium text-muted-foreground">Equipment Type</label>
                        <select
                          value={action.equipment_type_id || ""}
                          onChange={(e) => {
                            if (e.target.value === "__other__") {
                              updateAction(index, { equipment_type_id: "__other__" });
                              return;
                            }
                            updateAction(index, { equipment_type_id: e.target.value, equipment_type_other: "" });
                          }}
                          className="mt-1 w-full rounded border border-input bg-background px-2 py-1.5 text-xs"
                        >
                          <option value="">Optional...</option>
                          {equipment_types.map((type) => (
                            <option key={type.id} value={String(type.id)}>{type.name}</option>
                          ))}
                          <option value="__other__">Other (specify)</option>
                        </select>
                      </div>
                    </div>

                    {usingOtherType && (
                      <div>
                        <label className="text-xs font-medium text-muted-foreground">Other Equipment Type</label>
                        <Input
                          value={action.equipment_type_other}
                          onChange={(e) => updateAction(index, { equipment_type_other: e.target.value })}
                          className="mt-1 h-8 text-xs"
                          placeholder="e.g. Fan"
                        />
                      </div>
                    )}

                    <div className="grid grid-cols-1 sm:grid-cols-2 gap-2">
                      <div>
                        <label className="text-xs font-medium text-muted-foreground">Specific Equipment (optional)</label>
                        <select
                          value={action.equipment_entry_id}
                          onChange={(e) => updateAction(index, { equipment_entry_id: e.target.value })}
                          className="mt-1 w-full rounded border border-input bg-background px-2 py-1.5 text-xs"
                        >
                          <option value="">Optional...</option>
                          {attachable_equipment_entries.map((equipment) => (
                            <option key={equipment.id} value={String(equipment.id)}>
                              {equipment.label}
                            </option>
                          ))}
                        </select>
                      </div>
                      <div>
                        <label className="text-xs font-medium text-muted-foreground">Note (optional)</label>
                        <Input
                          value={action.note}
                          onChange={(e) => updateAction(index, { note: e.target.value })}
                          className="mt-1 h-8 text-xs"
                          placeholder="e.g. Drying complete"
                        />
                      </div>
                    </div>

                    <div className="flex justify-end">
                      <Button
                        type="button"
                        variant="ghost"
                        size="sm"
                        className="h-6 text-xs text-destructive hover:text-destructive"
                        onClick={() => removeAction(index)}
                      >
                        Remove Action
                      </Button>
                    </div>
                  </div>
                );
              })}
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
