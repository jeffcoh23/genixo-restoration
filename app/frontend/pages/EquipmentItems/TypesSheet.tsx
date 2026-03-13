import { Plus } from "lucide-react";
import InlineActionFeedback from "@/components/InlineActionFeedback";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Badge } from "@/components/ui/badge";
import { Dialog, DialogContent, DialogHeader, DialogTitle } from "@/components/ui/dialog";
import { Sheet, SheetContent, SheetHeader, SheetTitle, SheetDescription } from "@/components/ui/sheet";
import type { EquipmentTypeRow } from "./types";

export default function TypesSheet({
  open,
  onClose,
  all_types,
  addTypeOpen,
  onOpenAddType,
  onCloseAddType,
  typeName,
  setTypeName,
  typeSubmitting,
  onAddType,
  actionError,
  onDismissActionError,
  onDeactivateType,
  onReactivateType,
}: {
  open: boolean;
  onClose: () => void;
  all_types: EquipmentTypeRow[];
  addTypeOpen: boolean;
  onOpenAddType: () => void;
  onCloseAddType: () => void;
  typeName: string;
  setTypeName: (s: string) => void;
  typeSubmitting: boolean;
  onAddType: (e: React.FormEvent) => void;
  actionError: string | null;
  onDismissActionError: () => void;
  onDeactivateType: (path: string) => void;
  onReactivateType: (path: string) => void;
}) {
  return (
    <Sheet open={open} onOpenChange={(o) => !o && onClose()}>
      <SheetContent side="right" className="w-full sm:max-w-lg overflow-y-auto">
        <SheetHeader className="mb-6">
          <SheetTitle>Equipment Types</SheetTitle>
          <SheetDescription>
            Categories like "Dehumidifier" or "Air Mover". Items in your inventory belong to a type.
          </SheetDescription>
        </SheetHeader>

        <Button size="sm" className="mb-4 gap-1" onClick={onOpenAddType} disabled={typeSubmitting}>
          <Plus className="h-3.5 w-3.5" />
          Add Type
        </Button>

        <InlineActionFeedback error={actionError} onDismiss={onDismissActionError} className="mb-4" />

        {all_types.length === 0 ? (
          <p className="text-sm text-muted-foreground py-4">No types defined yet. Add one to get started.</p>
        ) : (
          <div className="rounded-lg border bg-card">
            <table className="w-full text-sm">
              <thead>
                <tr className="border-b bg-muted">
                  <th className="px-3 py-2 font-medium text-left">Name</th>
                  <th className="px-3 py-2 font-medium text-left">Status</th>
                  <th className="px-3 py-2 font-medium text-right">Actions</th>
                </tr>
              </thead>
              <tbody>
                {all_types.map((et) => (
                  <tr key={et.id} data-testid={`equipment-type-row-${et.id}`} className={`border-b last:border-0 ${!et.active ? "opacity-50" : ""}`}>
                    <td className="px-3 py-2.5 font-medium">{et.name}</td>
                    <td className="px-3 py-2.5">
                      {et.active ? (
                        <Badge variant="secondary" className="text-xs">Active</Badge>
                      ) : (
                        <Badge variant="outline" className="text-xs text-muted-foreground">Inactive</Badge>
                      )}
                    </td>
                    <td className="px-3 py-2.5 text-right">
                      {et.deactivate_path && (
                        <Button
                          variant="ghost"
                          size="sm"
                          className="h-7 text-xs text-muted-foreground hover:text-destructive"
                          onClick={() => onDeactivateType(et.deactivate_path!)}
                          disabled={typeSubmitting}
                          data-testid={`equipment-type-deactivate-${et.id}`}
                        >
                          Deactivate
                        </Button>
                      )}
                      {et.reactivate_path && (
                        <Button
                          variant="ghost"
                          size="sm"
                          className="h-7 text-xs"
                          onClick={() => onReactivateType(et.reactivate_path!)}
                          disabled={typeSubmitting}
                          data-testid={`equipment-type-reactivate-${et.id}`}
                        >
                          Reactivate
                        </Button>
                      )}
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        )}

        <Dialog open={addTypeOpen} onOpenChange={(o) => { if (!o) onCloseAddType(); }}>
          <DialogContent className="sm:max-w-sm">
            <DialogHeader>
              <DialogTitle>Add Equipment Type</DialogTitle>
            </DialogHeader>
            <form onSubmit={onAddType} className="space-y-4 mt-2">
              <div>
                <label className="text-sm font-medium">Name *</label>
                <Input
                  value={typeName}
                  onChange={(e) => setTypeName(e.target.value)}
                  placeholder="e.g. Dehumidifier"
                  className="mt-1"
                  autoFocus
                />
              </div>
              <div className="flex justify-end gap-2 pt-2">
                <Button type="button" variant="ghost" onClick={onCloseAddType}>Cancel</Button>
                <Button type="submit" disabled={!typeName.trim() || typeSubmitting}>
                  {typeSubmitting ? "Adding..." : "Add Type"}
                </Button>
              </div>
            </form>
          </DialogContent>
        </Dialog>
      </SheetContent>
    </Sheet>
  );
}
