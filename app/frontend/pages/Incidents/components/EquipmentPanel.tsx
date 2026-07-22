import { useMemo, useState } from "react";
import { Pencil, PackageMinus } from "lucide-react";
import InlineActionFeedback from "@/components/InlineActionFeedback";
import { Button } from "@/components/ui/button";
import { Dialog, DialogContent, DialogHeader, DialogTitle } from "@/components/ui/dialog";
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from "@/components/ui/select";
import useInertiaAction from "@/hooks/useInertiaAction";
import type { ConsumableDay, ConsumableType, EquipmentLogItem, EquipmentType } from "../types";
import ConsumablesSection from "./ConsumablesSection";
import EquipmentForm from "./EquipmentForm";
import IncidentPanelAddButton from "./IncidentPanelAddButton";

function equipmentLabel(item: EquipmentLogItem): string {
  const detail = item.tag_number
    ? `Tag #${item.tag_number}`
    : item.equipment_identifier
      ? `Serial ${item.equipment_identifier}`
      : item.location_notes;
  return detail ? `${item.type_name} · ${detail}` : item.type_name;
}

interface EquipmentPanelProps {
  equipment_log: EquipmentLogItem[];
  can_manage_equipment: boolean;
  equipment_entries_path: string;
  equipment_types: EquipmentType[];
  equipment_items_by_type?: Record<string, { id: number; identifier: string; tag_number: string | null; make: string | null; model_name: string | null }[]>;
  consumable_types?: ConsumableType[];
  consumable_days?: ConsumableDay[];
  consumable_entries_path: string;
  can_manage_consumables: boolean;
}

export default function EquipmentPanel({ equipment_log = [], can_manage_equipment, equipment_entries_path, equipment_types, equipment_items_by_type, consumable_types = [], consumable_days = [], consumable_entries_path, can_manage_consumables }: EquipmentPanelProps) {
  const [view, setView] = useState<"equipment" | "consumables">("equipment");
  const [showForm, setShowForm] = useState(false);
  const [editingEntry, setEditingEntry] = useState<EquipmentLogItem | null>(null);
  const [confirmRemove, setConfirmRemove] = useState<EquipmentLogItem | null>(null);
  const [filterType, setFilterType] = useState<string>("all");
  const [filterStatus, setFilterStatus] = useState<string>("all");
  const removeAction = useInertiaAction();

  const handleRemove = (item: EquipmentLogItem) => {
    if (!item.remove_path || removeAction.processing) return;
    setConfirmRemove(item);
  };

  const confirmAndRemove = () => {
    if (!confirmRemove?.remove_path) return;
    // Empty payload — server records Time.current, which is the actual
    // moment the user confirmed (not whenever the dialog opened).
    removeAction.runPatch(confirmRemove.remove_path, {}, {
      errorMessage: "Could not mark equipment as removed.",
      onSuccess: () => setConfirmRemove(null),
    });
  };

  const typeOptions = useMemo(() => {
    const seen = new Set<string>();
    return equipment_log
      .map((item) => item.type_name)
      .filter((name) => { if (seen.has(name)) return false; seen.add(name); return true; })
      .sort();
  }, [equipment_log]);

  const filtered = useMemo(() => {
    return equipment_log.filter((item) => {
      if (filterType !== "all" && item.type_name !== filterType) return false;
      if (filterStatus === "active" && item.removed_at_label) return false;
      if (filterStatus === "removed" && !item.removed_at_label) return false;
      return true;
    });
  }, [equipment_log, filterType, filterStatus]);

  const viewToggle = (
    <div className="flex rounded-md border border-border overflow-hidden shrink-0" role="tablist">
      {([ [ "equipment", "Equipment" ], [ "consumables", "Consumables" ] ] as const).map(([ key, label ]) => (
        <Button
          key={key}
          variant="ghost"
          size="sm"
          role="tab"
          aria-selected={view === key}
          onClick={() => setView(key)}
          data-testid={`equipment-view-${key}`}
          className={`h-8 rounded-none text-xs px-3 ${
            view === key ? "bg-muted font-semibold text-foreground" : "text-muted-foreground"
          }`}
        >
          {label}
        </Button>
      ))}
    </div>
  );

  if (view === "consumables") {
    return (
      <div className="flex flex-col h-full">
        <div className="flex items-center gap-2 border-b border-border px-4 py-3 shrink-0">
          {viewToggle}
        </div>
        <ConsumablesSection
          consumable_types={consumable_types}
          consumable_days={consumable_days}
          consumable_entries_path={consumable_entries_path}
          can_manage={can_manage_consumables}
        />
      </div>
    );
  }

  return (
    <div className="flex flex-col h-full">
      <div className="flex items-center gap-2 border-b border-border px-4 py-3 shrink-0 flex-wrap">
        {viewToggle}
        {can_manage_equipment && (
          <IncidentPanelAddButton
            label="Add Equipment"
            onClick={() => setShowForm(true)}
            className="w-full sm:w-auto"
          />
        )}
        <div className="flex w-full sm:w-auto items-center justify-center sm:justify-end gap-2 sm:ml-auto">
          <Select value={filterType} onValueChange={setFilterType}>
            <SelectTrigger data-testid="equipment-type-filter" className="h-10 sm:h-7 text-sm sm:text-xs w-[140px]">
              <SelectValue placeholder="All types" />
            </SelectTrigger>
            <SelectContent>
              <SelectItem value="all">All types</SelectItem>
              {typeOptions.map((t) => (
                <SelectItem key={t} value={t}>{t}</SelectItem>
              ))}
            </SelectContent>
          </Select>
          <Select value={filterStatus} onValueChange={setFilterStatus}>
            <SelectTrigger data-testid="equipment-status-filter" className="h-10 sm:h-7 text-sm sm:text-xs w-[120px]">
              <SelectValue placeholder="All" />
            </SelectTrigger>
            <SelectContent>
              <SelectItem value="all">All</SelectItem>
              <SelectItem value="active">Active</SelectItem>
              <SelectItem value="removed">Removed</SelectItem>
            </SelectContent>
          </Select>
        </div>
      </div>

      {removeAction.error && (
        <div className="px-4 pt-3">
          <InlineActionFeedback error={removeAction.error} onDismiss={removeAction.clearFeedback} />
        </div>
      )}

      {equipment_log.length === 0 ? (
        <div className="flex-1 flex items-center justify-center text-muted-foreground text-sm py-12">
          No equipment recorded yet.
        </div>
      ) : filtered.length === 0 ? (
        <div className="flex-1 flex items-center justify-center text-muted-foreground text-sm py-12">
          No equipment matches the current filters.
        </div>
      ) : (
        <div className="flex-1 overflow-y-auto">
          <div className="overflow-x-auto">
            <table className="w-full text-sm">
              <thead className="bg-muted border-b border-border sticky top-0">
                <tr>
                  <th className="px-4 py-3 text-left text-xs font-semibold uppercase tracking-wide text-muted-foreground">Category</th>
                  <th className="px-4 py-3 text-left text-xs font-semibold uppercase tracking-wide text-muted-foreground">Make</th>
                  <th className="px-4 py-3 text-left text-xs font-semibold uppercase tracking-wide text-muted-foreground">Model</th>
                  <th className="px-4 py-3 text-left text-xs font-semibold uppercase tracking-wide text-muted-foreground whitespace-nowrap">Serial #</th>
                  <th className="px-4 py-3 text-left text-xs font-semibold uppercase tracking-wide text-muted-foreground whitespace-nowrap">Tag #</th>
                  <th className="px-4 py-3 text-left text-xs font-semibold uppercase tracking-wide text-muted-foreground">Location</th>
                  <th className="px-4 py-3 text-left text-xs font-semibold uppercase tracking-wide text-muted-foreground">Placed</th>
                  <th className="px-4 py-3 text-left text-xs font-semibold uppercase tracking-wide text-muted-foreground">Removed</th>
                  <th className="px-4 py-3 text-right text-xs font-semibold uppercase tracking-wide text-muted-foreground w-[70px]">Hours</th>
                  {can_manage_equipment && (
                    <th className="px-4 py-3 w-[70px]" />
                  )}
                </tr>
              </thead>
              <tbody>
                {filtered.map((item) => (
                  <tr key={item.id} className="border-b border-border last:border-b-0 group hover:bg-muted/30 transition-colors">
                    <td className="px-4 py-3 text-sm font-medium text-foreground whitespace-nowrap">{item.type_name}</td>
                    <td className="px-4 py-3 text-sm text-muted-foreground">{item.equipment_make || "—"}</td>
                    <td className="px-4 py-3 text-sm text-muted-foreground">{item.equipment_model || "—"}</td>
                    <td className="px-4 py-3 text-sm text-muted-foreground whitespace-nowrap">{item.equipment_identifier || "—"}</td>
                    <td className="px-4 py-3 text-sm text-muted-foreground whitespace-nowrap">{item.tag_number || "—"}</td>
                    <td className="px-4 py-3 text-sm text-muted-foreground">{item.location_notes || "—"}</td>
                    <td className="px-4 py-3 text-sm text-muted-foreground whitespace-nowrap">{item.placed_at_label}</td>
                    <td className="px-4 py-3 text-sm text-muted-foreground whitespace-nowrap">{item.removed_at_label || "—"}</td>
                    <td className="px-4 py-3 text-sm text-muted-foreground text-right tabular-nums">{item.total_hours}</td>
                    {can_manage_equipment && (
                      <td className="px-2 py-2">
                        <div className="flex items-center gap-0.5">
                          {item.edit_path && (
                            <Button
                              variant="ghost"
                              size="sm"
                              className="h-6 w-6 p-0 text-muted-foreground hover:text-foreground"
                              onClick={() => setEditingEntry(item)}
                              title="Edit"
                            >
                              <Pencil className="h-3 w-3" />
                            </Button>
                          )}
                          {item.remove_path && (
                            <Button
                              variant="ghost"
                              size="sm"
                              className="h-6 w-6 p-0 text-muted-foreground hover:text-foreground"
                              onClick={() => handleRemove(item)}
                              disabled={removeAction.processing}
                              title="Pull equipment (sets removal time to now)"
                            >
                              <PackageMinus className="h-3 w-3" />
                            </Button>
                          )}
                        </div>
                      </td>
                    )}
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        </div>
      )}

      {showForm && (
        <EquipmentForm
          path={equipment_entries_path}
          equipment_types={equipment_types}
          equipment_items_by_type={equipment_items_by_type}
          onClose={() => setShowForm(false)}
        />
      )}

      <Dialog open={!!confirmRemove} onOpenChange={(open) => { if (!open) setConfirmRemove(null); }}>
        <DialogContent className="sm:max-w-sm">
          <DialogHeader>
            <DialogTitle>Pull this equipment?</DialogTitle>
          </DialogHeader>
          {confirmRemove && (
            <p className="text-sm text-muted-foreground">
              Mark <span className="font-medium text-foreground">{equipmentLabel(confirmRemove)}</span> as
              removed? Removal time will be recorded as now. You can edit it later from the equipment row.
            </p>
          )}
          <div className="flex justify-end gap-2 pt-2">
            <Button type="button" variant="ghost" onClick={() => setConfirmRemove(null)} disabled={removeAction.processing}>
              Cancel
            </Button>
            <Button type="button" onClick={confirmAndRemove} disabled={removeAction.processing}>
              {removeAction.processing ? "Pulling..." : "Pull equipment"}
            </Button>
          </div>
        </DialogContent>
      </Dialog>

      {editingEntry && editingEntry.edit_path && (
        <EquipmentForm
          path={equipment_entries_path}
          equipment_types={equipment_types}
          equipment_items_by_type={equipment_items_by_type}
          onClose={() => setEditingEntry(null)}
          entry={{
            id: editingEntry.id,
            type_name: editingEntry.type_name,
            equipment_make: editingEntry.equipment_make,
            equipment_model: editingEntry.equipment_model,
            equipment_identifier: editingEntry.equipment_identifier,
            tag_number: editingEntry.tag_number,
            placed_at_label: editingEntry.placed_at_label,
            removed_at_label: editingEntry.removed_at_label,
            active: !editingEntry.removed_at_label,
            location_notes: editingEntry.location_notes,
            logged_by_name: "",
            edit_path: editingEntry.edit_path,
            remove_path: editingEntry.remove_path,
            equipment_item_id: editingEntry.equipment_item_id ?? null,
            equipment_type_id: editingEntry.equipment_type_id ?? null,
            equipment_type_other: editingEntry.equipment_type_other ?? null,
            placed_at: editingEntry.placed_at,
            removed_at: editingEntry.removed_at ?? null,
          }}
        />
      )}
    </div>
  );
}
