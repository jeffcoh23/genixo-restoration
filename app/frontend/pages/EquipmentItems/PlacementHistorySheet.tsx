import { Sheet, SheetContent, SheetHeader, SheetTitle, SheetDescription } from "@/components/ui/sheet";
import { StatusBadge } from "./InventoryTable";
import type { EquipmentItemRow } from "./types";

export default function PlacementHistorySheet({
  item,
  onClose,
}: {
  item: EquipmentItemRow | null;
  onClose: () => void;
}) {
  if (!item) return null;

  return (
    <Sheet open={!!item} onOpenChange={(open) => !open && onClose()}>
      <SheetContent side="right" className="w-full sm:max-w-lg overflow-y-auto">
        <SheetHeader className="mb-6">
          <SheetTitle>{item.identifier}</SheetTitle>
          <SheetDescription>
            {item.type_name}
            {item.equipment_model ? ` — ${item.equipment_model}` : ""}
          </SheetDescription>
        </SheetHeader>

        <div className="mb-4">
          <StatusBadge deployed={item.deployed} property={item.deployed_property} />
        </div>

        {item.placements.length === 0 ? (
          <p className="text-sm text-muted-foreground py-4">No placement history yet.</p>
        ) : (
          <div className="space-y-0">
            <h4 className="text-xs font-semibold uppercase tracking-wider text-muted-foreground mb-3">
              Placement History
            </h4>
            <div className="relative">
              <div className="absolute left-[7px] top-2 bottom-2 w-px bg-border" />
              <div className="space-y-4">
                {item.placements.map((p, i) => (
                  <div key={i} className="relative pl-6">
                    <div
                      className={`absolute left-0 top-1.5 h-[15px] w-[15px] rounded-full border-2 ${
                        !p.removed_at
                          ? "border-status-warning bg-status-warning/15"
                          : "border-muted-foreground/30 bg-muted"
                      }`}
                    />
                    <div className="rounded-lg border bg-card p-3">
                      <div className="flex items-start justify-between gap-2">
                        <div className="min-w-0">
                          <p className="font-medium text-sm truncate">{p.property_name}</p>
                          {p.job_id && (
                            <p className="text-xs text-muted-foreground">Job: {p.job_id}</p>
                          )}
                        </div>
                        {!p.removed_at && (
                          <span className="shrink-0 rounded bg-status-warning/15 px-1.5 py-0.5 text-xs font-semibold uppercase text-status-warning">
                            Active
                          </span>
                        )}
                      </div>
                      <div className="mt-2 flex flex-wrap gap-x-4 gap-y-1 text-xs text-muted-foreground">
                        <span>Placed: {p.placed_at_formatted}</span>
                        {p.removed_at_formatted && <span>Removed: {p.removed_at_formatted}</span>}
                      </div>
                      {p.location_notes && (
                        <p className="mt-1.5 text-xs text-muted-foreground italic">
                          {p.location_notes}
                        </p>
                      )}
                    </div>
                  </div>
                ))}
              </div>
            </div>
          </div>
        )}
      </SheetContent>
    </Sheet>
  );
}
