import { useState } from "react";
import { router, usePage } from "@inertiajs/react";
import { Pencil, Plus, Trash2 } from "lucide-react";
import { Button } from "@/components/ui/button";
import { SharedProps } from "@/types";
import type { EquipmentLogItem, EquipmentType } from "../types";
import EquipmentForm from "./EquipmentForm";

interface EquipmentPanelProps {
  equipment_log: EquipmentLogItem[];
  can_manage_equipment: boolean;
  equipment_entries_path: string;
  equipment_types: EquipmentType[];
}

export default function EquipmentPanel({ equipment_log = [], can_manage_equipment, equipment_entries_path, equipment_types }: EquipmentPanelProps) {
  const { now_datetime } = usePage<SharedProps>().props;
  const [showForm, setShowForm] = useState(false);
  const [editingEntry, setEditingEntry] = useState<EquipmentLogItem | null>(null);

  const handleRemove = (item: EquipmentLogItem) => {
    if (!item.remove_path) return;
    router.patch(item.remove_path, { removed_at: now_datetime }, { preserveScroll: true });
  };

  return (
    <div className="flex flex-col h-full">
      {can_manage_equipment && (
        <div className="flex items-center gap-1 border-b border-border px-3 py-2 shrink-0">
          <Button variant="ghost" size="sm" className="h-7 text-xs gap-1" onClick={() => setShowForm(true)}>
            <Plus className="h-3 w-3" />
            Add Equipment
          </Button>
        </div>
      )}

      {equipment_log.length === 0 ? (
        <div className="flex-1 flex items-center justify-center text-muted-foreground text-sm py-12">
          No equipment recorded yet.
        </div>
      ) : (
        <div className="flex-1 overflow-y-auto">
          <div className="overflow-x-auto">
            <table className="w-full text-sm">
              <thead className="bg-muted border-b border-border sticky top-0">
                <tr>
                  <th className="px-3 py-2 text-left text-xs font-semibold uppercase tracking-wide text-muted-foreground">Type</th>
                  <th className="px-3 py-2 text-left text-xs font-semibold uppercase tracking-wide text-muted-foreground">Model</th>
                  <th className="px-3 py-2 text-left text-xs font-semibold uppercase tracking-wide text-muted-foreground w-[100px]">ID #</th>
                  <th className="px-3 py-2 text-left text-xs font-semibold uppercase tracking-wide text-muted-foreground">Location</th>
                  <th className="px-3 py-2 text-left text-xs font-semibold uppercase tracking-wide text-muted-foreground">Placed</th>
                  <th className="px-3 py-2 text-left text-xs font-semibold uppercase tracking-wide text-muted-foreground">Removed</th>
                  <th className="px-3 py-2 text-right text-xs font-semibold uppercase tracking-wide text-muted-foreground w-[70px]">Hours</th>
                  {can_manage_equipment && (
                    <th className="px-3 py-2 w-[70px]" />
                  )}
                </tr>
              </thead>
              <tbody>
                {equipment_log.map((item) => (
                  <tr key={item.id} className="border-b border-border last:border-b-0 group">
                    <td className="px-3 py-2 text-sm font-medium text-foreground">{item.type_name}</td>
                    <td className="px-3 py-2 text-sm text-muted-foreground">{item.equipment_model || "—"}</td>
                    <td className="px-3 py-2 text-sm text-muted-foreground">{item.equipment_identifier || "—"}</td>
                    <td className="px-3 py-2 text-sm text-muted-foreground">{item.location_notes || "—"}</td>
                    <td className="px-3 py-2 text-sm text-muted-foreground whitespace-nowrap">{item.placed_at_label}</td>
                    <td className="px-3 py-2 text-sm text-muted-foreground whitespace-nowrap">{item.removed_at_label || "—"}</td>
                    <td className="px-3 py-2 text-sm text-muted-foreground text-right tabular-nums">{item.total_hours}</td>
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
          onClose={() => setShowForm(false)}
        />
      )}

      {editingEntry && editingEntry.edit_path && (
        <EquipmentForm
          path={equipment_entries_path}
          equipment_types={equipment_types}
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
