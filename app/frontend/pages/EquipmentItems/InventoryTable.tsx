import { Pencil, MapPin, CircleCheck } from "lucide-react";
import { Button } from "@/components/ui/button";
import type { EquipmentItemRow } from "./types";

function StatusBadge({ deployed, property }: { deployed: boolean; property: string | null }) {
  if (deployed) {
    return (
      <span className="inline-flex items-center gap-1 rounded-full bg-status-warning/15 px-2 py-0.5 text-xs font-medium text-status-warning">
        <MapPin className="h-3 w-3" />
        {property}
      </span>
    );
  }

  return (
    <span className="inline-flex items-center gap-1 rounded-full bg-status-success/15 px-2 py-0.5 text-xs font-medium text-status-success">
      <CircleCheck className="h-3 w-3" />
      Available
    </span>
  );
}

export { StatusBadge };

export default function InventoryTable({
  items,
  submitting,
  onEdit,
  onDeactivate,
  onViewHistory,
}: {
  items: EquipmentItemRow[];
  submitting: boolean;
  onEdit: (item: EquipmentItemRow) => void;
  onDeactivate: (item: EquipmentItemRow) => void;
  onViewHistory: (item: EquipmentItemRow) => void;
}) {
  return (
    <div className="rounded-lg border bg-card shadow-sm">
      <table className="w-full text-sm">
        <thead>
          <tr className="border-b bg-muted">
            <th className="px-4 py-3 font-medium text-left">Serial #</th>
            <th className="px-4 py-3 font-medium text-left">Tag #</th>
            <th className="px-4 py-3 font-medium text-left">Category</th>
            <th className="px-4 py-3 font-medium text-left">Make</th>
            <th className="px-4 py-3 font-medium text-left">Model</th>
            <th className="px-4 py-3 font-medium text-left">Status</th>
            <th className="px-4 py-3 font-medium text-right">Actions</th>
          </tr>
        </thead>
        <tbody>
          {items.map((item) => (
            <tr key={item.id} data-testid={`equipment-item-row-${item.id}`} className="border-b last:border-0 hover:bg-muted">
              <td className="px-4 py-3">
                <Button
                  variant="link"
                  className="h-auto p-0 font-medium"
                  onClick={() => onViewHistory(item)}
                  data-testid={`equipment-item-history-${item.id}`}
                >
                  {item.identifier}
                </Button>
              </td>
              <td className="px-4 py-3 text-muted-foreground">{item.tag_number || "—"}</td>
              <td className="px-4 py-3 text-muted-foreground">{item.type_name}</td>
              <td className="px-4 py-3 text-muted-foreground">{item.equipment_make || "—"}</td>
              <td className="px-4 py-3 text-muted-foreground">{item.equipment_model || "—"}</td>
              <td className="px-4 py-3">
                <StatusBadge deployed={item.deployed} property={item.deployed_property} />
              </td>
              <td className="px-4 py-3 text-right">
                <div className="flex items-center justify-end gap-1">
                  <Button
                    variant="ghost"
                    size="sm"
                    className="h-7 w-7 p-0 text-muted-foreground"
                    onClick={() => onEdit(item)}
                    disabled={submitting}
                    data-testid={`equipment-item-edit-${item.id}`}
                  >
                    <Pencil className="h-3.5 w-3.5" />
                  </Button>
                  <Button
                    variant="ghost"
                    size="sm"
                    className="h-7 text-xs text-muted-foreground"
                    onClick={() => onDeactivate(item)}
                    disabled={submitting}
                    data-testid={`equipment-item-deactivate-${item.id}`}
                  >
                    Remove
                  </Button>
                </div>
              </td>
            </tr>
          ))}
        </tbody>
      </table>
    </div>
  );
}
