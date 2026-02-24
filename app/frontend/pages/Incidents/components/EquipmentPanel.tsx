import { useMemo, useState } from "react";
import { usePage } from "@inertiajs/react";
import { Pencil, Plus, Trash2 } from "lucide-react";
import InlineActionFeedback from "@/components/InlineActionFeedback";
import { Button } from "@/components/ui/button";
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from "@/components/ui/select";
import useInertiaAction from "@/hooks/useInertiaAction";
import { SharedProps } from "@/types";
import type { EquipmentLogItem, EquipmentType } from "../types";
import EquipmentForm from "./EquipmentForm";

interface EquipmentPanelProps {
  equipment_log: EquipmentLogItem[];
  can_manage_equipment: boolean;
  equipment_entries_path: string;
  equipment_types: EquipmentType[];
  equipment_items_by_type?: Record<string, { id: number; identifier: string; model_name: string | null }[]>;
}

export default function EquipmentPanel({ equipment_log = [], can_manage_equipment, equipment_entries_path, equipment_types, equipment_items_by_type }: EquipmentPanelProps) {
  const { today } = usePage<SharedProps>().props;
  const [showForm, setShowForm] = useState(false);
  const [editingEntry, setEditingEntry] = useState<EquipmentLogItem | null>(null);
  const [filterType, setFilterType] = useState<string>("all");
  const [filterStatus, setFilterStatus] = useState<string>("all");
  const removeAction = useInertiaAction();

  const handleRemove = (item: EquipmentLogItem) => {
    if (!item.remove_path || removeAction.processing) return;
    removeAction.runPatch(item.remove_path, { removed_at: today }, {
      errorMessage: "Could not mark equipment as removed.",
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

  return (
    <div className="flex flex-col h-full">
      <div className="flex items-center gap-2 border-b border-border px-4 py-3 shrink-0 flex-wrap">
        {can_manage_equipment && (
          <Button variant="ghost" size="sm" className="h-7 text-xs gap-1" onClick={() => setShowForm(true)}>
            <Plus className="h-3 w-3" />
            Add Equipment
          </Button>
        )}
        <div className="flex items-center gap-2 ml-auto">
          <Select value={filterType} onValueChange={setFilterType}>
            <SelectTrigger data-testid="equipment-type-filter" className="h-7 text-xs w-[140px]">
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
            <SelectTrigger data-testid="equipment-status-filter" className="h-7 text-xs w-[120px]">
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
                  <th className="px-4 py-3 text-left text-xs font-semibold uppercase tracking-wide text-muted-foreground">Type</th>
                  <th className="px-4 py-3 text-left text-xs font-semibold uppercase tracking-wide text-muted-foreground">Model</th>
                  <th className="px-4 py-3 text-left text-xs font-semibold uppercase tracking-wide text-muted-foreground whitespace-nowrap">ID #</th>
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
                    <td className="px-4 py-3 text-sm text-muted-foreground">{item.equipment_model || "—"}</td>
                    <td className="px-4 py-3 text-sm text-muted-foreground whitespace-nowrap">{item.equipment_identifier || "—"}</td>
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
                              className="h-6 w-6 p-0 text-muted-foreground hover:text-destructive"
                              onClick={() => handleRemove(item)}
                              disabled={removeAction.processing}
                              title="Mark as removed"
                            >
                              <Trash2 className="h-3 w-3" />
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

      {editingEntry && editingEntry.edit_path && (
        <EquipmentForm
          path={equipment_entries_path}
          equipment_types={equipment_types}
          equipment_items_by_type={equipment_items_by_type}
          onClose={() => setEditingEntry(null)}
          entry={{
            id: editingEntry.id,
            type_name: editingEntry.type_name,
            equipment_model: editingEntry.equipment_model,
            equipment_identifier: editingEntry.equipment_identifier,
            placed_at_label: editingEntry.placed_at_label,
            removed_at_label: editingEntry.removed_at_label,
            active: !editingEntry.removed_at_label,
            location_notes: editingEntry.location_notes,
            logged_by_name: "",
            edit_path: editingEntry.edit_path,
            remove_path: editingEntry.remove_path,
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
