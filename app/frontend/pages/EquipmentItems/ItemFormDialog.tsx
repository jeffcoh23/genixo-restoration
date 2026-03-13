import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from "@/components/ui/select";
import { Dialog, DialogContent, DialogHeader, DialogTitle } from "@/components/ui/dialog";
import type { EquipmentTypeOption, ItemForm } from "./types";

interface ItemFormDialogProps {
  open: boolean;
  onClose: () => void;
  form: ItemForm;
  setForm: (f: ItemForm) => void;
  equipment_types: EquipmentTypeOption[];
  submitting: boolean;
  onSubmit: (e: React.FormEvent) => void;
  title: string;
  submitLabel: string;
  submittingLabel: string;
}

export default function ItemFormDialog({
  open,
  onClose,
  form,
  setForm,
  equipment_types,
  submitting,
  onSubmit,
  title,
  submitLabel,
  submittingLabel,
}: ItemFormDialogProps) {
  return (
    <Dialog open={open} onOpenChange={(o) => !o && onClose()}>
      <DialogContent className="sm:max-w-md">
        <DialogHeader>
          <DialogTitle>{title}</DialogTitle>
        </DialogHeader>
        <form onSubmit={onSubmit} className="space-y-4 mt-2">
          <div>
            <label className="text-sm font-medium">Category *</label>
            <Select value={form.equipment_type_id} onValueChange={(v) => setForm({ ...form, equipment_type_id: v })}>
              <SelectTrigger className="mt-1">
                <SelectValue placeholder="Select category..." />
              </SelectTrigger>
              <SelectContent>
                {equipment_types.map((t) => (
                  <SelectItem key={t.id} value={String(t.id)}>{t.name}</SelectItem>
                ))}
              </SelectContent>
            </Select>
          </div>
          <div>
            <label className="text-sm font-medium">Serial Number *</label>
            <Input
              value={form.identifier}
              onChange={(e) => setForm({ ...form, identifier: e.target.value })}
              placeholder="e.g. 108447"
              className="mt-1"
            />
          </div>
          <div>
            <label className="text-sm font-medium">Tag Number</label>
            <Input
              value={form.tag_number}
              onChange={(e) => setForm({ ...form, tag_number: e.target.value })}
              placeholder="e.g. 1010"
              className="mt-1"
            />
          </div>
          <div className="grid grid-cols-2 gap-3">
            <div>
              <label className="text-sm font-medium">Make</label>
              <Input
                value={form.equipment_make}
                onChange={(e) => setForm({ ...form, equipment_make: e.target.value })}
                placeholder="e.g. Drieaz"
                className="mt-1"
              />
            </div>
            <div>
              <label className="text-sm font-medium">Model</label>
              <Input
                value={form.equipment_model}
                onChange={(e) => setForm({ ...form, equipment_model: e.target.value })}
                placeholder="e.g. LGR 5000 LI-127690"
                className="mt-1"
              />
            </div>
          </div>
          <div className="flex justify-end gap-2 pt-2">
            <Button type="button" variant="ghost" onClick={onClose} disabled={submitting}>Cancel</Button>
            <Button type="submit" disabled={!form.identifier.trim() || !form.equipment_type_id || submitting}>
              {submitting ? submittingLabel : submitLabel}
            </Button>
          </div>
        </form>
      </DialogContent>
    </Dialog>
  );
}
